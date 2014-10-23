# this is hacky but we really don't want to depend on sensu just for spec
IN_RSPEC = true

module Sensu
  module Plugin
    EXIT_CODES = {
      'OK'       => 0,
      'WARNING'  => 1,
      'CRITICAL' => 2,
      'UNKNOWN'  => 3 }

    class Check
      class CLI
        def self.method_missing(*args); end
      end
    end
  end
end
