module Puppet::Parser::Functions
  newfunction(:annotation_guess, :type => :rvalue, :doc => <<-EOS
  Determines the location (file:line) of the declaration for the current
  resource.  Useful for creating links to documentation automaticall from
  Puppet code.

  Doesn't work with the 'include' function (e.g. include sshd) or
  resources created with create_resources.
  EOS
  ) do |args|
    scope = self
    resource = scope.resource

    # Travel two directories up to determine the size of the prefix to chop off
    # This is a cheap and ugly hack
    sizeof_prefix = File.dirname(File.dirname(scope.environment.manifest)).length + 1

    if scope.resource.file and scope.resource.line
      "%s:%d" % [resource.file[sizeof_prefix..-1], resource.line]
    else
      "Unknown"
    end
  end
end
