#!/opt/sensu/embedded/bin/ruby

$: << File.dirname(__FILE__)

require 'rubygems'
unless defined?(IN_RSPEC)
  require 'sensu-plugin/utils'
  require 'sensu-plugin/check/cli'
end
require 'json'
require 'net/https'

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
    :description => 'filter clients to analyze',
    :default    => ''

  option :remote_sensu,
    :short       => '-h host',
    :long        => '--remote-sensu host',
    :description => 'remote sensu server to use',
    :required    => true

  option :json,
    :short       => '-j',
    :long        => '--json',
    :boolean     => true,
    :description => 'json output for critical alert, false by default',
    :default     => false

  attr_reader :bad

  def run
    find_triggered_events

    if bad.empty?
      ok "Remote sensu #{config[:remote_sensu]} has 0 triggered #{config[:event]} events for clients that match '#{config[:filter]}'."
    else
      if config[:json]
        critical({
          :remote_sensu  => config[:remote_sensu],
          :filter        => config[:filter],
          :event         => config[:event],
          :critical      => bad,
        }.to_json)
      else
        critical "Remote sensu #{config[:remote_sensu]} has #{bad.size} triggered #{config[:event]} events for clients that match '#{config[:filter]}': #{bad.inspect}"
      end
    end
  rescue => e
    unknown "Failed to connect to remote sensu #{config[:remote_sensu]} - #{e}"
  end

  def find_triggered_events
    @bad = Array.new
    events = JSON.parse(api_request(:Get, '/events').body)
    events.each do |ev|
      next unless ev['check']['name'] == config[:event]
      next unless ev['client'].to_s.include? config[:filter]
      @bad << ev['client']['name']
    end
    @bad
  end

  def api_request(method, path)
    raise "api.json settings not found." unless settings.has_key?('api')
    open_timeout = settings['api'].fetch('open_timeout', 10),
    read_timeout = settings['api'].fetch('read_timeout', 10)
    Net::HTTP.start(config[:remote_sensu], settings['api']['port'],
                    :read_timeout => read_timeout) do |http|
      http.open_timeout = open_timeout
      req = Net::HTTP.const_get(method).new(path)
      if settings['api']['user'] && settings['api']['password']
        req.basic_auth(settings['api']['user'], settings['api']['password'])
      end
      req = yield(req) if block_given?
      http.request(req)
    end
  end

end
