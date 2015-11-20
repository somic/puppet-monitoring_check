#
# SensuFleetCheck - manage events for individual clients from central location
#
# Sometimes it makes more sense instead of running a check on each individual
# client to run it somewhere in one location but still trigger events for
# each client. One example is query EC2 API and check each host in response
# vs have each host query EC2 API about itself. Another example could be
# trigger event only on 5 worst performing hosts out of many clients.
#
# You need to override build_event_lists to build
# trigger_list and resolve_list as shown in example below. Fleet check will do
# the rest.
#
# Fleet checks are only meant to be deployed with monitoring_check::server_side.
#
# By default, 'team' parameter for triggered alerts will be taken from puppet
# definition of this check. Include { 'with_keepalive_team' => true } in
# sensu_custom parameter if you want fleet check to look up the team
# that gets keepalive events for this host and use that team instead.
#
# Example:
#
# $: << '/etc/sensu/plugins'
# require 'fleet_check'
#
# class MyCheck < SensuFleetCheck
#   @@autorun = self # this is needed unfortunately
#
#   # define cmd line options you want to accept
#   # (optional)
#   option :event_name,
#     :short => '-e event_name',
#     :required => true
#
#   def build_event_lists
#     trigger_list << { :sensu_client_name => 'host1.fqdn',
#                       :status => 2,
#                       :output => 'failed' }
#     trigger_list << { :sensu_client_name => 'host2.fqdn',
#                       :status => 2,
#                       :output => 'exception' }
#     resolve_list << 'host3.fqdn' << 'host4.fqdn'
#   end
#
# end
require 'sensu-plugin/utils'
require 'sensu-plugin/check/cli'
require 'tiny_redis'
require 'socket'
require 'json'
require 'net/http'

class SensuFleetCheck < Sensu::Plugin::Check::CLI

  include Sensu::Plugin::Utils

  attr_accessor :trigger_list, :resolve_list, :extra_msgs

  def run
    begin
      do_run
    rescue => e
      ok "Exception: msg='#{e.message}' backtrace=#{e.backtrace}"
    end
  end

  def do_run
    fleet_check_init if respond_to?(:fleet_check_init)
    raise("event_name bad or missing") if event_name.nil? || event_name.empty?

    @extra_msgs = []
    @trigger_list = [ ]
    @resolve_list = [ ]
    build_event_lists
    trigger_list.each { |event| trigger(event) }
    resolve_list.each { |sensu_client| resolve(sensu_client) }

    msgs = []
    msgs << "triggered: #{trigger_list.map {|t| t[:sensu_client_name] }.join(',')}" if
            trigger_list.any?
    msgs << "resolved: #{resolve_list.join(',')}" if resolve_list.any?
    msgs << 'no action taken, both trigger_list and resolve_list are empty' if
            trigger_list.empty? && resolve_list.empty?
    msgs += extra_msgs if extra_msgs.any?
    ok msgs.join(' ')
  end

  def event_name
    config[:event_name] || @event_name || raise('event name is not set')
  end

  # override build_event_lists OR
  # override build_trigger_list and built_resolve_list
  def build_event_lists
    build_trigger_list
    build_resolve_list
  end

  def build_trigger_list
    warn 'Probably want to override build_trigger_list'
  end

  def build_resolve_list
    warn 'Probably want to override build_resolve_list'
  end

  def trigger(event)
    # here is the dependency on server side check
    check = settings['checks']["server_side_placeholder_for_#{event_name}"]
    new_event = { 'source' => event[:sensu_client_name],
                  'name' => event_name,
                  'status' => event[:status],
                  'output' => event[:output],
                  'handlers' => check['actual_handlers'],
                  'command' => check['actual_command'] }
    [ :dependencies, :interval, :alert_after, :realert_every,
      :runbook, :sla, :team, :irc_channels, :notification_email,
      :ticket, :page, :tip, :habitat, :tags, :timeout, :standalone,
    ].each do |k|
      new_event[k.to_s] = check[k.to_s]
    end

    if check['with_keepalive_team']
      team_override = get_client_keepalive_team(event[:sensu_client_name])
      new_event['team'] = team_override if team_override
    end

    begin
      sock = TCPSocket.new('127.0.0.1', 3030)
      sock.puts(new_event.to_json)
      sock.close

      redis.rpush(redis_key, event[:sensu_client_name]) unless
        event_already_triggered?(event[:sensu_client_name])
    rescue => e
      @extra_msgs << "trigger_fail(#{event[:sensu_client_name]}): #{e.message}"
      return
    end
  end

  def resolve(sensu_client)
    # sensu docs say they will return HTTP 202 Accepted
    if api_request(:Delete, "/events/#{sensu_client}/#{event_name}").code =~ /20/
      redis.lrem(redis_key, 1, sensu_client)
    end
  end

  def clients_with_triggered_event
    # FIXME - when we run for the first time, redis_key will not be in redis
    # and this value will end up []. An improvement over this would be
    # to go over existing "result:*:#{event_key}" keys in redis and build a list
    # of sensu clients with this event. Maybe not worth implementing this
    # for just a first run though
    @clients_with_triggered_event ||= redis.lrange(redis_key, 0, -1) || []
  end

  def event_already_triggered?(sensu_client_name)
    clients_with_triggered_event.include? sensu_client_name
  end

  def redis
    @redis ||= TinyRedis::Client.new(host=settings['redis']['host'],
                                     port=settings['redis']['port'])
  end

  def redis_key
    "fleet_check:#{event_name}"
  end

  # based on api_request method in sensu-handler.rb but with
  # better timeout handling (see also do_api_request method)
  def api_request(method, path)
    begin
      do_api_request(method, path)
    rescue Timeout::Error
      @extra_msgs << "api_timeout(#{method},#{path})"
      nil
    end
  end

  def do_api_request(method, path)
    raise "api.json settings not found." unless settings.has_key?('api')
    open_timeout = settings['api'].fetch('open_timeout', 10),
    read_timeout = settings['api'].fetch('read_timeout', 10)
    Net::HTTP.start(settings['api']['host'], settings['api']['port'],
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

  def get_client_keepalive_team(client_name)
    begin
      client_data = JSON.parse(redis.get("client:#{client_name}"))
      client_data['keepalive']['team']
    rescue
      nil
    end
  end

end
