#!/usr/bin/env ruby
#
# Check Cluster
#

require 'rubygems'
require 'pry'
require 'sensu'
require 'sensu/settings'
require 'sensu/transport'
require 'sensu/redis'
require 'sensu-plugin/check/cli'

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

  ##############################################################################

  option :api,
    :short => "-a URL",
    :long => "--api URL",
    :description => "Sensu API URL",
    :default => "http://localhost:4567"

  option :user,
    :short => "-u USER",
    :long => "--user USER",
    :description => "Sensu API USER"

  option :password,
    :short => "-p PASSWORD",
    :long => "--password PASSWORD",
    :description => "Sensu API PASSWORD"

  option :timeout,
    :short => "-t SECONDS",
    :long => "--timeout SECONDS",
    :description => "Sensu API connection timeout in SECONDS",
    :proc => proc {|a| a.to_i },
    :default => 30

  option :check,
    :short => "-c CHECK",
    :long => "--check CHECK",
    :description => "Aggregate CHECK name",
    :required => true

  option :age,
    :short => "-A SECONDS",
    :long => "--age SECONDS",
    :description => "Minimum aggregate age in SECONDS, time since check request issued",
    :default => 30,
    :proc => proc {|a| a.to_i }

  option :limit,
    :short => "-l LIMIT",
    :long => "--limit LIMIT",
    :description => "Limit of aggregates you want the API to return",
    :proc => proc {|a| a.to_i }

  option :summarize,
    :short => "-s",
    :long => "--summarize",
    :boolean => true,
    :description => "Summarize check result output",
    :default => false

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

  option :pattern,
    :short => "-P PATTERN",
    :long => "--pattern PATTERN",
    :description => "A PATTERN to detect outliers"

  option :message,
    :short => "-M MESSAGE",
    :long => "--message MESSAGE",
    :description => "A custom error MESSAGE"

  ##############################################################################

  def run
    locked_run do
      status, output = check_aggregate
      send_payload status, output
      ok "Check executed successfully"
    end
  end

  def check_aggregate
    binding.pry
    # TODO: do not hardcode this?
    args = ARGV.join(' ').
             gsub(/(-S|--server-config)\s*[^\s]+/, '').
             gsub(/(-L|--lock-timeout)\s*[^\s]+/, '')
    cmd = "/usr/share/sensu-community-plugins/plugins/sensu/check-aggregate.rb #{args}"
    out = `#{cmd}`
    res = $?
    return res, out
  end

private

  def locked_run
    # TODO: pyramid of doom!
    EM::run do
      begin
        redis.setnx(lock_key, Time.now.to_i) do |created|
          if created
            redis.pexpire(lock_key, config[:lock_timeout]) do
              yield
              EM::stop
            end
          else
            EM::stop
          end
        end
      rescue Exception => e
        critical "#{e.message} (#{e.class})\n#{e.backtrace.join "\n"}"
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

  def send_payload
    payload = config.dup

    if sensu_settings.check_exists?(config[:name])
      payload.merge!(sensu_settings[:checks][config[:name]])
    end
  end
end
