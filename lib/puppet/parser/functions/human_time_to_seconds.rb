module Puppet::Parser::Functions

  newfunction(:human_time_to_seconds, :type => :rvalue, :doc => <<-'ENDHEREDOC'
    Converts a human time of the form Xs, Xm or Xh into an integer number of seconds

    ENDHEREDOC
    ) do |args|

    unless args.length == 1 then
      raise Puppet::ParseError, ("human_time_to_seconds(): wrong number of arguments (#{args.length}; must be 1)")
    end
    arg = args[0]
    unless arg.respond_to?('to_s') then
      raise Puppet::ParseError, ("#{arg.inspect} is not a string. It looks to be a #{arg.class}")
    end

    data = arg.to_s.scan(/^(\d+)(\w)?$/)
    if data.size != 1
      raise Puppet::ParseError, ("#{arg} is not of the form \d+[hms]")
    end

    mult = 1
    case data[0][1]
    when nil, 's'
    when 'm'
      mult = 60
    when 'h'
      mult = 60*60
    else
      raise Puppet::ParseError, ("#{arg} multiplier '#{data[0][1]};' not known, only know s, m, g")
    end
    time = data[0][0].to_i * mult
    time.to_s
  end
end

