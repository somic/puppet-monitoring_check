#!/opt/sensu/embedded/bin/ruby

require 'rubygems'
require 'json'
require 'net/http'
require 'sensu-plugin/utils'
require 'sensu-plugin/check/cli'

class WatchdogMetaCheck < Sensu::Plugin::Check::CLI

  include Sensu::Plugin::Utils

  def run
    watchdog_stashes.each do |stash|
      # stash is a hash which probably looks like this (here is an example
      # of a silence stash):
      # { "path" => "silence/hostname",
      #   "content" => {
      #     "reason" =>"reason text",
      #     "source" =>"source text",
      #     "timestamp" => "1432146791.0"
      #   },
      #   "expire" => 9029}

      # FIXME: do something meaningful here
      p stash
    end
    ok 'completed successfully'
  end

  def watchdog_stashes
    # TODO: what if server paginates?
    @watchdog_stashes ||= JSON.parse(api_request(:GET, '/stashes').body).select { |x|
                            x['path'].start_with? 'watchdog/' }
  end

  # api_request from Sensu::Handler
  def api_request(method, path, &blk)
    http = Net::HTTP.new(settings['api']['host'], settings['api']['port'])
    req = net_http_req_class(method).new(path)
    if settings['api']['user'] && settings['api']['password']
      req.basic_auth(settings['api']['user'], settings['api']['password'])
    end
    yield(req) if block_given?
    http.request(req)
  end

end
