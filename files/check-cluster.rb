#!/usr/bin/env ruby
#
# Check Cluster
#

# TODO: manage this via puppet?
$: << "/usr/share/sensu-community-plugins/plugins"

require 'rubygems'
require 'pry'
require 'sensu'
require 'sensu/settings'
require 'sensu/transport'
require 'sensu/redis'
load 'sensu/check-aggregate.rb'

class CheckCluster < Sensu::Plugin::Check::CLI
  option :server_config,
    :short => "-S FILE",
    :long => "--server-config FILE",
    :description => "Sensu server config file",
    :default => "/etc/sensu/config.json"

  option :lock_timeout,
    :short => "-L SECONDS",
    :long => "--lock-timeout SECONDS",
    :description => "TTL on redis lock, usually same as check interval",
    :default => 60

  option :check,
    :short => "-c CHECK",
    :long => "--check CHECK",
    :description => "Aggregate CHECK name",
    :required => true

  def run
    binding.pry
    status = nil
    EM::run { status = locked_run { check_aggregate } }
    Kernel.exit status
  end

  def check_aggregate
    @output = capture_stdout { CheckAggregate.new.run }
  rescue SystemExit => e
    @status = e.status
  end

private

  def locked_run(&block)
    lock(&block)
    p @output
    p @status

    ok
  rescue SystemExit => e
    exit e.status
  rescue Exception => e
    critical "\n#{e.backtrace.join "\n"}: #{e.message} (#{e.class})"
  end

  def lock(&block)
    puts "redis queried"
    redis.setnx(lock_key, Time.now.to_i) do |created|
      puts "lock acquired: " << created.inspect
      if created
        redis.pexpire(lock_key, config[:lock_timeout]) do
          block.call
          puts "#lock done"
          EM::stop
        end
      else
        EM::stop
      end
    end
  end

  def lock_key
    "lock:check_cluster:#{config[:check]}"
  end

  def redis
    @redis ||= Sensu::Redis.connect(sensu_settings[:redis])
  end

  def sensu_settings
    @sensu_settings ||= Sensu::Settings.get(:config_file => config[:server_config])
  end

  def setup_transport
    transport_name = sensu_settings[:transport][:name] || 'rabbitmq'
    transport_settings = sensu_settings[transport_name]
    @transport = Transport.connect(transport_name, transport_settings)
  end

  def payload
    payload = config.dup

    if sensu_settings.check_exists?(config[:name])
      payload.merge!(sensu_settings[:checks][config[:name]])
    end
  end

  def capture_stdout
    out = StringIO.new
    $stdout = out
    yield
    return out
  ensure
    $stdout = STDOUT
  end

  def exit(status)
    status
  end
end
