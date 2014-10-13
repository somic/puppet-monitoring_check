#!/opt/sensu/embedded/bin/ruby
#
# Check Cluster
#

require 'socket'
require 'net/http'

require 'rubygems'
require 'sensu'
require 'sensu/settings'
require 'sensu-plugin/check/cli'
require 'json'

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
    :required => true

  option :warning,
    :short => "-W PERCENT",
    :long => "--warning PERCENT",
    :description => "PERCENT non-ok before warning",
    :proc => proc {|a| a.to_i }

  option :critical,
    :short => "-C PERCENT",
    :long => "--critical PERCENT",
    :description => "PERCENT non-ok before critical",
    :proc => proc {|a| a.to_i }

  def run
    locked_run do
      status, output = check_aggregate
      send_payload status, output
      ok "Check executed successfully"
    end
  end

private

  EXIT_CODES = Sensu::Plugin::EXIT_CODES

  def check_aggregate
    path   = "/aggregates/#{config[:check]}"
    issued = api_request(path, :age => 30)

    return EXIT_CODES['WARNING'], "No aggregates for #{config[:check]}" if issued.empty?
    time = issued.sort.last

    return EXIT_CODES['WARNING'], "No aggregates older than #{config[:age]} seconds" unless time

    aggregate = api_request("#{path}/#{time}")
    check_thresholds(aggregate) { |status, msg| return status, msg }
    # check_pattern(aggregate) { |status, msg| return status, msg }

    return EXIT_CODES['OK'], "Aggregate looks GOOD"
  end

  # yielding means end of checking and sending payload to sensu
  def check_thresholds(aggregate)
    nz_pct  = ((1 - aggregate["ok"].to_f / aggregate["total"].to_f) * 100).to_i
    message = "Number of non-zero results exceeds threshold (#{nz_pct}% non-zero)"

    if config[:critical] && percent_non_zero >= config[:critical]
      yield EXIT_CODES['CRITICAL'], message
    elsif config[:warning] && percent_non_zero >= config[:warning]
      yield EXIT_CODES['WARNING'], message
    end
  end

  def api_request(path, opts={})
    api = sensu_settings[:api]
    uri = URI("http://#{api[:host]}:#{api[:port]}#{path}")
    uri.query = URI.encode_www_form(opts)

    req = Net::HTTP::Get.new(uri)
    req.basic_auth api[:user], api[:password]

    res = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(req)
    end

    if res.is_a?(Net::HTTPSuccess)
      JSON.parse(res.body)
    else
      raise "Error querying sensu api: #{res.code} '#{res.body}'"
    end
  end

  def locked_run
    if redis.setnx(lock_key, Time.now.to_i) == 1
      redis.expire(lock_key, lock_interval)
      yield
    else
      if (ttl = Time.now.to_i - redis.get(lock_key).to_i) > lock_interval
        redis.expire(lock_key, 0)
        warning "was locked for #{ttl} seconds, expired immediately"
      else
        ok "lock expires in #{lock_interval - ttl} seconds"
      end
    end
  rescue RuntimeError => e
    critical "#{e.message} (#{e.class})\n#{e.backtrace.join "\n"}"
  ensure
    redis.close
  end

  def lock_key
    "lock:#{config[:cluster_name]}:#{config[:check]}"
  end

  # assume convention for naming aggregate checks as <cluster_name>_<check_name>
  # default to aggregated check interval or 300 seconds
  def lock_interval
    (cluster_check || target_check || {})[:interval] || 300
  end

  def redis
    @redis ||= TinyRedisClient.new(
      sensu_settings[:redis][:host], sensu_settings[:redis][:port])
  end

  def sensu_settings
    @sensu_settings ||=
      Sensu::Settings.get(:config_dirs => ["/etc/sensu/conf.d"])
  end

  def send_payload(status, output)
    payload =
      target_check.merge(
        :status => status,
        :output => output,
        :source => config[:cluster_name],
        :name   => config[:check])

    payload[:runbook] = cluster_check[:runbook] if cluster_check[:runbook]
    payload.delete :command

    sock = TCPSocket.new('localhost', 3030)
    sock.puts payload.to_json
    sock.close
  end

  def cluster_check
    sensu_settings[:checks][:"#{config[:cluster]}_#{config[:check]}"]
  end

  def target_check
    sensu_settings[:checks][config[:check]]
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
