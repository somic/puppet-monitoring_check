#!/opt/sensu/embedded/bin/ruby
#
# Check Cluster
#

require 'socket'
require 'net/http'

if !defined?(IN_RSPEC)
  require 'rubygems'
  require 'sensu'
  require 'sensu/constants' # version is here
  require 'sensu/settings'
  require 'sensu-plugin/check/cli'
  require 'json'
end

class CheckCluster < Sensu::Plugin::Check::CLI
  option :cluster_name,
    :short => "-N NAME",
    :long => "--cluster-name NAME",
    :description => "Name of the cluster to use in the source of the alerts",
    :required => true

  option :check,
    :short => "-c CHECK",
    :long => "--check CHECK",
    :description => "Aggregate CHECK name",
    :required => true,
    :default => 80

  option :critical,
    :short => "-C PERCENT",
    :long => "--critical PERCENT",
    :description => "PERCENT non-ok before critical",
    :proc => proc {|a| a.to_i }

  option :silenced,
    :short => "-S yes",
    :long => "--silenced yes",
    :description => "Include silenced hosts in total",
    :default => false

  option :dryrun,
    :short => "-d",
    :long => "--dry-run",
    :description => "Run cluster check without any redis locking or sensu alerting",
    :default => false

  option :verbose,
    :short => "-v",
    :long => "--verbose",
    :description => "Print debug information",
    :default => false

  def run
    unless check_sensu_version
      unknown "Sensu <0.13 is not supported"
      return
    end

    if !cluster_check[:interval]
      critical "Please configure interval"
      return
    end

    $VERBOSE = !!config[:verbose]

    lock_key = "lock:#{config[:cluster_name]}:#{config[:check]}"
    interval = cluster_check[:interval]
    target_interval = cluster_check[:target_interval] || cluster_check[:interval]

    if config[:dryrun]
      status, output = check_aggregate(aggregator.summary(target_interval))
      ok "Dry run cluster check successfully executed, with output: (#{status}: #{output})"
      return
    end

    locked_run(self, redis, lock_key, interval, Time.now.to_i, logger) do
      status, output = check_aggregate(aggregator.summary(target_interval))
      logger.puts output
      send_payload EXIT_CODES[status], output
      ok "Cluster check successfully executed, with output: (#{status}: #{output})"
      return
    end

    unknown "Check didn't report status"
  rescue RuntimeError => e
    critical "#{e.message} (#{e.class}): #{e.backtrace.inspect}"
  end

private

  def aggregator
    RedisCheckAggregate.new(redis, config[:check])
  end

  def check_sensu_version
    # good enough
    Sensu::VERSION.split('.')[1].to_i > 12
  end

  EXIT_CODES = Sensu::Plugin::EXIT_CODES

  def logger
    $stdout
  end

  def locked_run(*args, &block)
    RedisLocker.new(*args).run(&block)
  end

  def redis
    @redis ||= begin
      redis_config = sensu_settings[:redis] or raise "Redis config not available"
      TinyRedisClient.new(redis_config[:host], redis_config[:port])
    end
  end

  # accept summary:
  #   total:    all server that had ran the check in the past
  #   ok:       number of *active* servers with check status OK
  #   silenced: number of *total* servers that are silenced or have
  #             target check silenced
  def check_aggregate(summary)
    total, ok, silenced = summary.values_at(:total, :ok, :silenced)
    return 'OK', 'No servers running the check' if total.zero?

    eff_total = total - silenced * (config[:silenced] ? 1 : 0)
    return 'OK', 'All hosts silenced' if eff_total.zero?

    ok_pct  = (100 * ok / eff_total.to_f).to_i

    message = "#{ok} OK out of #{eff_total} total."
    message << " #{silenced} silenced." if config[:silenced] && silenced > 0
    message << " (#{ok_pct}% OK, #{config[:critical]}% threshold)"

    state = ok_pct >= config[:critical] ? 'OK' : 'CRITICAL'
    return state, message
  end

  def sensu_settings
    @sensu_settings ||=
      Sensu::Settings.get(:config_dirs => ["/etc/sensu/conf.d"]) or
      raise "Sensu settings not available"
  end

  def send_payload(status, output)
    payload = cluster_check.merge(
      :status => status,
      :output => output,
      :source => config[:cluster_name],
      :name   => config[:check])
    payload.delete :command

    sock = TCPSocket.new('localhost', 3030)
    sock.puts payload.to_json
    sock.close
  end

  def cluster_check
    return {} if ENV['DEBUG']
    return JSON.parse(ENV['DEBUG_CC']) if ENV['DEBUG_CC']

    @cluster_check ||=
      sensu_settings[:checks][:"#{config[:cluster_name]}_#{config[:check]}"] or
        raise "#{config[:cluster_name]}_#{config[:check]} not found"
  end
end

class RedisLocker
  attr_reader :status, :redis, :key, :interval, :now, :logger

  def initialize(status, redis, key, interval, now = Time.now.to_i, logger = $stdout)
    raise "Redis connection check failed" unless "hello" == redis.echo("hello")

    @status   = status
    @redis    = redis
    @key      = key
    @interval = interval.to_i
    @now      = now
    @logger   = logger
  end

  def run
    expire if ENV['DEBUG_UNLOCK']

    if redis.setnx(key, now) == 1
      logger.puts "Lock acquired"

      begin
        expire interval
        yield
      rescue => e
        expire
        status.critical "Releasing lock due to error: #{e} #{e.backtrace}"
        raise e
      end
    elsif locked_at = redis.get(key).to_i
      if (time_alive = now - locked_at) > interval
        expire
        status.ok "Lock problem: #{now} - #{locked_at} > #{interval}, expired immediately"
      else
        status.ok "Lock expires in #{interval - time_alive} seconds"
      end
    else
      status.ok "Lock slipped away"
    end
  end

private

  def expire(seconds=0)
    redis.pexpire(@key, seconds*1000)
  end
end

class TinyRedisClient
  RN = "\r\n"

  def initialize(host='localhost', port=6379)
    @socket = TCPSocket.new(host, port)
  end

  def method_missing(method, *args)
    args.unshift method
    data = ["*#{args.size}", *args.map {|arg| "$#{arg.to_s.size}#{RN}#{arg}"}]
    @socket.write(data.join(RN) << RN)
    parse_response
  end

  def parse_response
    case @socket.gets
    when /^\+(.*)\r\n$/ then $1
    when /^:(\d+)\r\n$/ then $1.to_i
    when /^-(.*)\r\n$/  then raise "Redis error: #{$1}"
    when /^\$([-\d]+)\r\n$/
      $1.to_i >= 0 ? @socket.read($1.to_i+2)[0..-3] : nil
    when /^\*([-\d]+)\r\n$/
      $1.to_i > 0 ? (1..$1.to_i).inject([]) { |a,_| a << parse_response } : nil
    end
  end

  def close
    @socket.close
  end
end

class RedisCheckAggregate
  def initialize(redis, check)
    @check = check
    @redis = redis
  end

  def summary(interval)
    # we only care about entries with executed timestamp
    all     = last_execution(find_servers).select{|_,data| data[0]}
    active  = all.select { |_, data| data[0].to_i >= Time.now.to_i - interval }

    if $VERBOSE
      puts "All #{all.length} hosts' latest result with timestamp for check #{@check}:\n#{all}\n\n"
      puts "All #{active.length} hosts with #{@check} that have responded in the last #{interval} seconds:\n#{active}\n\n"
    end

    stale = all.keys - active.keys
    failing = active.select{ |_,data| data[1].to_i == 2}

    unless stale.empty?
      puts "The results for the following #{stale.length} hosts are stale (occured more than #{interval} seconds ago):\n#{stale}\n\n"
    end
    unless failing.empty?
      puts "The following #{failing.length} hosts are failing the check #{@check}:\n#{failing}\n\n"
    end

    { :total    => all.size,
      :ok       => active.count{ |_,data| data[1].to_i == 0 },
      :silenced => all.count do |server, time|
        [server, @check, "#{server}/#@check"].map{|s| "stash:silence/#{s}"}.
          any? {|key| @redis.get(key) }
      end }
  end

  private

  # { server_name => [timestamp, status], ... }
  def last_execution(servers)
    servers.inject({}) do |hash, server|
      hash.merge!(
        server => JSON.parse(@redis.get("result:#{server}:#@check")).
                    values_at("executed", "status"))
    end
  end

  def find_servers
    # TODO: reimplement using @redis.scan for webscale
    @servers ||= @redis.keys("result:*:#@check").map {|key| key.split(':')[1]}
  end
end
