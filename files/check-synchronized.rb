#!/opt/sensu/embedded/bin/ruby

$: << "#{File.dirname(__FILE__)}/lib"

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

  attr_accessor :check, :check_name
  attr_reader :configuration

  def run
    File.open(config[:config]) { |f| @configuration = JSON.parse(f.read) }
    File.open("#{configuration['sensu_checks_dir']}/#{config[:check]}.json") { |f|
      check_json = JSON.parse(f.read)["checks"]
      @check_name, @check =  check_json.keys.first, check_json.values.first
    }

    distributed_mutex.synchronize {
      check["command"] = check.delete("actual_command")
      check.merge!(
        "executed" => Time.now.to_i,
        "name" => check_name
      )
      check["output"] = `#{check["command"]}`
      check["status"] = $?.exitstatus
      send_event_to_local_sensu_client
    }

    ok
  end

  def redis
    @redis ||= TinyRedis::Client.new(host=configuration["redis_server"],
                                     port=configuration["redis_port"])
  end

  def distributed_mutex
    @mutex = TinyRedis::Mutex.new(redis,
                                  "synchronized_check_mutex::::#{check_name}",
                                  check["interval"] || 60,
                                  $stdout)
  end

  def send_event_to_local_sensu_client
    check["issued"] = Time.now.to_i
    sock = TCPSocket.new('127.0.0.1', configuration['sensu_client_port'])
    sock.puts(check.to_json)
    sock.close
  end
end
