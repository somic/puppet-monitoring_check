require 'spec_helper'

describe 'monitoring_check::server_side' do

  let(:title) { 'example1' }

  let(:hiera_data) {{
    'monitoring_check::params::team_data' => { 'qux' => { } },
  }}

  let(:facts) {{
    :ipaddress => '127.0.0.1',
    :osfamily => 'Debian',
    :lsbdistid => 'Ubuntu',
    :lsbdistcodename => 'Lucid',
    :operatingsystem => 'Ubuntu',
    :puppetversion => '3.6.2',
    :habitat       => 'somehabitat',
  }}

  let(:pre_condition) { 'include sensu' }

  context 'by default' do
    let(:params) {{
      :command => 'foo', :runbook => 'y/bar', :source => 'baz',
      :team => 'qux', :page => true
    }}

    it {
      should contain_class('monitoring_check::server_side::install')
      should contain_monitoring_check('server_side_placeholder_for_example1') \
               .with_command(/check_server_side.rb/) \
               .with_page(false) \
               .with_sensu_custom(
                 'actual_command' => 'foo',
                 'actual_name'    => 'example1',
                 'source'         => 'baz',
                 'actual_page'    => true,
                 'actual_ticket'  => false,
                 'actual_notification_email' => 'undef',
               )
    }
  end

  context 'with event_name' do
    let(:params) {{
      :command => 'foo', :runbook => 'y/bar', :source => 'baz',
      :team => 'qux', :event_name => 'hello_world', :ticket => true
    }}

    it {
      should contain_monitoring_check('server_side_placeholder_for_example1') \
        .with_ticket(false) \
        .with_sensu_custom(
          'actual_command' => 'foo',
          'actual_name'    => 'hello_world',
          'source'         => 'baz',
          'actual_page'    => false,
          'actual_ticket'  => true,
          'actual_notification_email' => 'undef'
        )
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
