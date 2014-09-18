require 'spec_helper'

describe 'human_time_to_seconds' do
  Puppet::Parser::Functions.function(:human_time_to_seconds)
  def call(*args); subject.call([*args]); end
  def fail; raise_error Puppet::Parser::Functions::HumanTimeError; end

  it { should run.with_params('30').and_return('30') }
  it { should run.with_params('30s').and_return('30') }
  it { should run.with_params('2m').and_return('120') }
  it { should run.with_params('2h').and_return('7200') }

  it('works with ints')            { expect { call 30 }.not_to raise_error }
  it('fails with no args')         { expect { call }.to fail }
  it('fails with too many args')   { expect { call '1m', '2m' }.to fail }
  it('fails with not stringable')  { expect { call Class.new.new }.to fail }
  it('fails given unknown suffix') { expect { call '40z' }.to fail }
  it('fails if no integer')        { expect { call 'm' }.to fail }
  it('fails given non-int')        { expect { call '3.2s' }.to fail }
  it('fails given wrong format')   { expect { call ' 3s' }.to fail }
end
