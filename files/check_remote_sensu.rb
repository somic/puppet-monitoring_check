#!/opt/sensu/embedded/bin/ruby

$: << File.dirname(__FILE__)

require 'rubygems'
unless defined?(IN_RSPEC)
  require 'sensu-plugin/utils'
  require 'sensu-plugin/check/cli'
end
require 'json'
require 'net/https'
require 'sensu_api_util'

class CheckRemoteSensu < Sensu::Plugin::Check::CLI

  # let's get all sensu settings
  include Sensu::Plugin::Utils
  include SensuAPIUtil

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

  option :preserve_output,
    :short       => '-p',
    :long        => '--preserve-output',
    :boolean     => true,
    :description => 'use output from remote events that we found',
    :default     => false

  attr_reader :bad

  def run
    find_triggered_events

    if bad.empty?
      ok "Remote sensu #{config[:remote_sensu]} has 0 triggered #{config[:event]} events for clients that match '#{config[:filter]}'."
    else
      if config[:preserve_output]
        critical("#{config[:event]} " + @bad_outputs.join('.'))
      elsif config[:json]
        puts({
          :remote_sensu  => config[:remote_sensu],
          :filter        => config[:filter],
          :event         => config[:event],
          :critical      => bad,
        }.to_json)
        exit 2
      else
        critical "Remote sensu #{config[:remote_sensu]} has #{bad.size} triggered #{config[:event]} events for clients that match '#{config[:filter]}': #{bad.inspect}"
      end
    end
  rescue => e
    unknown "Failed to connect to remote sensu #{config[:remote_sensu]} - #{e}"
  end

  def find_triggered_events
    @bad = Array.new
    @bad_outputs = Array.new
    events = json_parse_api_request(config[:remote_sensu], :Get, '/events')
    events.each do |ev|
      next unless ev['check']['name'] == config[:event]
      next unless ev['client'].to_s.include? config[:filter]
      @bad << ev['client']['name']
      @bad_outputs << ev['check']['output'].to_s
    end
    @bad
  end

end
