#!/opt/sensu/embedded/bin/ruby

$: << File.dirname(__FILE__) + '/lib'

require 'rubygems'
require 'sensu-plugin/check/cli'
require 'tiny_redis'
require 'socket'
require 'json'

class CheckSynchronized < Sensu::Plugin::Check::CLI

  option :check,
    :short => '-c check_name',
    :long => '--check check_name',
    :description => 'name of the check',
    :required => true

  option :config,
    :short => '-f config_file',
    :long => '--config config_file',
    :description => 'path to synchronized check config json file',
    :required => true

  attr_accessor :check, :check_name, :new_check
  attr_reader :configuration

  def run
    File.open(config[:config]) { |f|
      @configuration = JSON.parse(f.read, :symbolize_names => true) }
    File.open("#{configuration[:sensu_checks_dir]}/#{config[:check]}.json") { |f|
      check_json = JSON.parse(f.read, :symbolize_names => true)[:checks]
      @check_name, @check =  check_json.keys.first, check_json.values.first
    }

    distributed_mutex.synchronize {
      @new_check = { :executed => Time.now.to_i }.merge(check)
      new_check[:command] = new_check.delete(:actual_command)
      new_check[:name] = new_check.delete(:actual_name)
      new_check[:output] = `( #{new_check[:command]} ) 2>&1`
      new_check[:status] = $?.success? ? 0 : 2
      new_check[:issued] = Time.now.to_i
      send_new_check_event_to_local_sensu_client
    }

    check[:foo] = 'bar'
    check.delete :source
    ok "noop"
  end

  def redis
    @redis ||= TinyRedis::Client.new(host=configuration[:redis_server],
                                     port=configuration[:redis_port])
  end

  def distributed_mutex
    mutex_expiration = check[:interval] > 5 ? check[:interval] - 5 : 1
    @mutex = TinyRedis::Mutex.new(redis,
                                  "synchronized_check_mutex::::#{check_name}",
                                  mutex_expiration,
                                  $stdout)
  end

  def send_new_check_event_to_local_sensu_client
    sock = TCPSocket.new('127.0.0.1', configuration[:sensu_client_port])
    sock.puts(new_check.to_json)
    sock.close
  end
end
