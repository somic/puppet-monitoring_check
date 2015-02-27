#!/opt/sensu/embedded/bin/ruby
#
#

# FIXME
$: << 'lib'
ARBITRARY_NUMBER_1 = 10

require 'rubygems'
require 'sensu-plugin/check/cli'
require 'tiny_redis'
require 'socket'
require 'json'

class CheckSynchronized < Sensu::Plugin::Check::CLI

  option :redis_server,
    :short => '-H host',
    :long => '--redis-server host',
    :description => 'redis server hostname/IP to connect to',
    :default => '127.0.0.1'

  option :redis_port,
    :short => '-P port',
    :long => '--redis-port port',
    :description => 'redis port to connect to',
    :default => 6379

  option :check,
    :short => '-c checkfile',
    :long => '--check checkfile',
    :description => 'check definition json file',
    :required => true

  attr_accessor :check, :check_name

  def run
    File.open(config[:check]) { |f|
      check_json = JSON.parse(f.read)["checks"]
      @check_name, @check =  check_json.keys.first, check_json.values.first
    }
   
    rc = nil
    distributed_mutex.synchronize {
      check.merge! "executed" => Time.now.to_i,
                   "name"     => check_name
      check["output"] = `#{check["command"]}`
      # TODO only OK or CRITICAL now, do we need more status codes? TBD
      check["status"] = $? ? 0 : 2
    }

    send_event_to_local_sensu_client
    ok
  end

  def redis
    @redis ||= TinyRedis::Client.new(config[:redis_server], config[:redis_port])
  end

  def distributed_mutex
    TinyRedis::Mutex.new(redis, mutex_key, ARBITRARY_NUMBER_1, logger)
  end

  def logger
    @logger ||= $stdout
  end

  def mutex_key
    @mutex_key ||= "synchronized_check_mutex::::#{check_name}"
  end

  def send_event_to_local_sensu_client
    check["issued"] = Time.now.to_i
    sock = TCPSocket.new('127.0.0.1', 3030)
    sock.puts check.to_json
    sock.close
  end
end
