#
# Helpers to facilitate talking to sensu api
#
require 'net/https'
require 'json'

module SensuAPIUtil
  def api_request(host, method, path)
    begin
      settings
    rescue
      raise 'your class needs to include Sensu::Plugin::Utils'
    end
    raise 'api.json settings not found.' unless settings.has_key?('api')

    open_timeout = settings['api'].fetch('open_timeout', 10)
    read_timeout = settings['api'].fetch('read_timeout', 10)
    Net::HTTP.start(host, settings['api']['port'],
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

  def json_parse_api_request(host, method, path)
    JSON.parse(api_request(host, method, path).body)
  end
end
