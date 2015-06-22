#!/opt/sensu/embedded/bin/ruby

$: << File.dirname(__FILE__)

require 'rubygems'
require 'sensu-plugin/utils'
require 'sensu-plugin/check/cli'
require 'tiny_redis'
require 'socket'
require 'json'

class CheckServerSide < Sensu::Plugin::Check::CLI

  # let's get all sensu settings
  include Sensu::Plugin::Utils

  option :check,
    :short => '-c check_name',
    :long => '--check check_name',
    :description => 'name of the check',
    :required => true

  attr_reader :check, :new_check

  def run
    begin
      do_run
    rescue => e
      # intentionally never let placeholder check fail -
      # log unexpected issues for debugging instead
      ok "ran actual check: exception: msg='#{e.message}' backtrace=#{e.backtrace}"
    end
  end

  def do_run
    @check = settings['checks'][config[:check]]

    # try to obtain "lock" from redis;
    # if successful - create and execute new check.
    # if failed to obtain the lock - do nothing.
    distributed_mutex.run_with_lock_or_skip {
      # let's clone this check into a new object, adjust some fields,
      # execute its command and explicitly send the result of new check
      # to local redis-client process
      @new_check = { 'executed' => Time.now.to_i }.merge(check)

      %w( command name page ticket notification_email ).each { |field|
        new_check[field] = new_check.delete("actual_#{field}")
      }

      new_check['output'] = `( #{new_check['command']} ) 2>&1`.strip
      new_check['status'] = $?.exitstatus
      new_check['issued'] = Time.now.to_i
      send_new_check_event_to_local_sensu_client
    }

    # placeholder check never does anything interesting and we never ever
    # want to see it in uchiwa or anywhere else
    if @new_check
      ok "ran actual check: exit_code=#{new_check['status']} output='#{new_check['output']}'"
    else
      ok "skipped actual check: lock detected ttl=#{@mutex.ttl} seconds"
    end
  end

  def redis
    # settings will include redis server information on sensu servers but
    # not on sensu clients
    @redis ||= TinyRedis::Client.new(host=settings['redis']['host'],
                                     port=settings['redis']['port'])
  end

  def distributed_mutex
    mutex_expiration = check['interval'] > 5 ? check['interval'] - 5 : 1
    @mutex = TinyRedis::Mutex.new(redis,
                                  "check_server_side_mutex::::#{config[:check]}",
                                  mutex_expiration,
                                  $stdout)
  end

  def send_new_check_event_to_local_sensu_client
    sock = TCPSocket.new('127.0.0.1', 3030)
    sock.puts(new_check.to_json)
    sock.close
  end
end
