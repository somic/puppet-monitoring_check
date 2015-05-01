require 'spec_helper'

describe 'monitoring_check::server_side' do

  let(:title) { 'example1' }
  let('::sensu::check_notify') { 'foo' }

  let(:hiera_data) {{
    'monitoring_check::params::team_data' => { 'qux' => { } },
  }}

  context "by default" do
    let(:params) {{
      :command => 'foo', :runbook => 'y/bar', :source => 'baz',
      :team => 'qux',
    }}
    it {
      should contain_class('monitoring_check::server_side::install')
      should contain_monitoring_check('server_side_placeholder_for_example1') \
               .with_command(/check_server_side.rb/) \
               .with_sensu_custom({
                 'actual_command' => 'foo',
                 'actual_name'    => 'example1',
                 'source'         => 'baz'
               })
    }
  end
  
end
