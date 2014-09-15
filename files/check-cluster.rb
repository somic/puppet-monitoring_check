#!/usr/bin/env ruby
#
# Check Cluster
#

require 'rubygems'
require 'sensu'
require 'sensu/settings'
require 'sensu/transport'
require 'sensu/redis'
require 'sensu-plugin/check/cli'
require 'json'

class CheckCluster < Sensu::Plugin::Check::CLI
  option :cluster_name,
    :short => "-N NAME",
    :long => "--cluster-name NAME",
    :description => "Cluster name to prefix occurrences",
    :required => true

  option :server_config,
    :short => "-S FILE",
    :long => "--server-config FILE",
    :description => "Sensu server config file",
    :default => "/etc/sensu/config.json"

  option :server_config_dir,
    :short => "-D DIR",
    :long => "--server-config-dir DIR",
    :description => "Sensu server config directory",
    :default => "/etc/sensu/conf.d"

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
    # TODO: do not hardcode this?
    args = ARGV.join(' ').
             gsub(/(-S|--server-config)\s*[^\s]+/, '').
             gsub(/(-L|--lock-timeout)\s*[^\s]+/, '').
             gsub(/(-D|--server-config-dir)\s*[^\s]+/, '').
             gsub(/(-N|--cluster-name)\s*[^\s]+/, '')
    cmd = "/usr/share/sensu-community-plugins/plugins/sensu/check-aggregate.rb #{args}"
    output = `#{cmd}`
    result = $?.exitstatus
    return result, output
  end

private

  def locked_run
    # TODO: pyramid of doom! i'm horrible with EM
    EM::run do
      begin
        redis.setnx(lock_key, Time.now.to_i) do |created|
          puts "lock acquired: " << created.inspect
          if created
            redis.expire(lock_key, config[:lock_timeout]) do |result|
              puts "locked: " << result.inspect
              yield
              EM::stop
            end
          else
            redis.get(lock_key) do |age|
              ttl = Time.now.to_i - age.to_i
              if ttl > config[:lock_timeout].to_i
                redis.expire(lock_key, 0) do
                  EM::stop
                  warning "was locked for #{ttl} seconds, expired immediately"
                end
              else
                EM::stop
                ok "lock expires in #{config[:lock_timeout] - ttl} seconds"
              end
            end
          end
        end
      rescue Exception => e
        critical "#{e.message} (#{e.class})\n#{e.backtrace.join "\n"}"
      end
    end
  end

  def lock_key
    "lock:#{config[:cluster_name]}:#{config[:check]}"
  end

  def redis
    @redis ||= Sensu::Redis.connect(sensu_settings[:redis])
  end

  def sensu_settings
    @sensu_settings ||=
      Sensu::Settings.get(
        :config_file => config[:server_config],
        :config_dirs => [config[:server_config_dir]])
  end

  def setup_transport
    transport_name = sensu_settings[:transport][:name] || 'rabbitmq'
    transport_settings = sensu_settings[transport_name]
    @transport = Transport.connect(transport_name, transport_settings)
  end

  def send_payload(status, output)
    payload = {
      :client => sensu_settings[:client],
      :occurrences => 1,
      :action => :create,
      :check  => sensu_settings[:checks][config[:check]].merge(
        :status => status,
        :output => output,
        :source => "#{config[:cluster_name]}_#{config[:check]}")
    }

    puts payload.to_json
  end
end
