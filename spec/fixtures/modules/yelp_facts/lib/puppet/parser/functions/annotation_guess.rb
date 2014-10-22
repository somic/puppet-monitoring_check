module Puppet::Parser::Functions
  newfunction(:annotation_guess, :type => :rvalue, :doc => <<-EOS
  # Mock stand-in for the real function. See the real function for docs.
  EOS
  ) do |args|
    'annotation:1'
  end
end
