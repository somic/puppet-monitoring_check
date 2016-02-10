require 'spec_helper'

describe 'monitoring_check::server_side' do

  let(:title) { 'example1' }

  let(:hiera_data) {{
    'monitoring_check::params::team_data' => { 'qux' => { } },
  }}

  let(:facts) {{
    :ipaddress        => '127.0.0.1',
    :osfamily         => 'Debian',
    :lsbdistid        => 'Ubuntu',
    :lsbdistcodename  => 'Lucid',
    :operatingsystem  => 'Ubuntu',
    :puppetversion    => '3.6.2',
    :habitat          => 'somehabitat',
    :fqdn             => 'host1',
  }}

  let(:pre_condition) { %q{
    include apt
    include sensu
  } }

  context 'by default' do
    let(:params) {{
      :command => 'foo', :runbook => 'y/bar', :source => 'baz',
      :team => 'qux', :tags => ['test']
    }}

    it {
      should contain_class('monitoring_check::server_side::install')
      should contain_monitoring_check('server_side_placeholder_for_example1') \
               .with_command(/check_server_side.rb/) \
               .with_source('baz') \
               .with_tags(['server_side', 'executed_by host1', 'test'])
               .with_sensu_custom({
                 'actual_command' => 'foo',
                 'actual_name'    => 'example1',
                 'actual_handlers'=> [ 'default' ],
               })
    }
  end

  context 'with event_name and handlers' do
    let(:params) {{
      :command => 'foo', :runbook => 'y/bar', :source => 'baz',
      :team => 'qux', :event_name => 'hello_world', :handlers => [ 'foo' ]
    }}

    it {
      should contain_monitoring_check('server_side_placeholder_for_example1') \
        .with_source('baz') \
        .with_sensu_custom({
          'actual_command' => 'foo',
          'actual_name'    => 'hello_world',
          'actual_handlers'=> [ 'foo' ],
        })
    }
  end

  context 'with event_name as not a string' do
    let(:params) {{
      :command => 'foo', :runbook => 'y/bar', :source => 'baz',
      :team => 'qux', :event_name => [42]
    }}

    it {
      expect { should compile }.to raise_error(/not a string/)
    }
  end

end
