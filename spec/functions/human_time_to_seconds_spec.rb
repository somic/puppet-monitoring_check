require 'spec_helper'

describe 'human_time_to_seconds' do
 
  # Fix for https://github.com/rodjek/rspec-puppet/issues/44?
  before(:each) do
    Puppet::Parser::Functions.function(:human_time_to_seconds)
  end

  it { should run.with_params('30').and_return('30') }
  it { should run.with_params('30s').and_return('30') }
  it { should run.with_params('1m').and_return('60') }
  it { should run.with_params('1h').and_return('3600') }

  it 'should work' do
    expect { subject.call([30]) }.not_to raise_error()
  end

  it 'should fail with no args' do
    expect { subject.call([]) }.to raise_error(Puppet::ParseError)
  end
  it 'should fail with many args' do
    expect { subject.call(['foo', 'bar']) }.to raise_error(Puppet::ParseError)
  end
  it 'should fail if given insane data type' do
    expect { subject.call([ [] ]) }.to raise_error(Puppet::ParseError)
  end
  it 'should fail if given unknown suffix' do
    expect { subject.call([ ['40z'] ]) }.to raise_error(Puppet::ParseError)
  end
  it 'should fail if no integer' do
    expect { subject.call([ ['m'] ]) }.to raise_error(Puppet::ParseError)
  end
  it 'should fail if given non-int' do
    expect { subject.call([ ['3.2s'] ]) }.to raise_error(Puppet::ParseError)
  end
  it 'should fail if given wrong format' do
    expect { subject.call([ [' 3s'] ]) }.to raise_error(Puppet::ParseError)
  end


end

