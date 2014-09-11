#!/usr/bin/env ruby
#
# Check Cluster
#

# TODO: manage this via puppet?
$: << "/usr/share/sensu-community-plugins/plugins"

require 'rubygems'
require 'sensu-settings'
require 'redis'
require 'check-aggregate.rb'

class CheckCluster < CheckAggregate
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

  def run
    lock { super }
  end

private
  def lock(&block)
    redis.setnx(lock_key, Time.now.to_i) do |created|
      return unless created

      redis.pexpire(lock_key, config[:lock_timeout])
      block.call
    end
  end

  def lock_key
    "lock:check_cluster:#{config[:check]}"
  end

  def redis
    @redis ||= Redis.connect(sensu_settings[:redis])
  end

  def sensu_settings
    Sensu::Settings.get(:config_file => config[:server_config])
  end
end
