#!/opt/sensu/embedded/bin/ruby

$: << File.dirname(__FILE__)

require 'rubygems'
unless defined?(IN_RSPEC)
  require 'sensu-plugin/utils'
  require 'sensu-plugin/check/cli'
end
require 'tiny_redis'
require 'socket'
require 'json'

class CheckRemoteSensu < Sensu::Plugin::Check::CLI

  # let's get all sensu settings
  include Sensu::Plugin::Utils

  option :event,
    :short       => '-e event',
    :long        => '--event check_name',
    :description => 'name of the event',
    :required    => true

  option :filter,
    :short       => '-f filter',
    :long        => '--filter filter',
    :description => 'filter hosts to analyze',
    :required    => true

  option :redis_host,
    :short       => '-h host',
    :long        => '--redis-host host',
    :description => 'redis host to use',
    :required    => true

  attr_accessor :good, :bad, :undefined

  def run
    @good = []
    @bad = []
    @undefined = []

    redis.keys("result:*:#{config[:event]}").each do |key|
      _, host, _ = key.split(/:/)
      next unless redis.get("client:#{host}").include?(config[:filter])
      check_result = JSON.parse(redis.get(key)) rescue nil
      case check_result['status']
        when 0
          good << host
        when 2
          bad << host
        else
          undefined << host
      end
    end

    unknown("No check results were found. #{message}") if (bad + good + undefined).empty?

    bad.empty? ? ok(message) : critical(message)
  end

  def redis
    @redis ||= TinyRedis::Client.new(host=config[:redis_host],
                                     port=settings['redis']['port'])
    @redis.ping
    @redis
  rescue => e
    raise "Unable to connect to remote redis at #{config[:redis_host]} : #{e.message}"
  end

  def message
    m = ""
    m += message_part(bad, :critical) unless bad.empty?
    m += message_part(good, :ok) unless good.empty?
    m += message_part(undefined, :unknown) unless undefined.empty?
    m += " Host filter applied during search: '#{config[:filter]}'."
    m.gsub(/\s+/, ' ')
  end

  def message_part(list, status_string)
    "#{config[:event]} is #{status_string} on these hosts: #{list.join(', ')}. "
  end

end
