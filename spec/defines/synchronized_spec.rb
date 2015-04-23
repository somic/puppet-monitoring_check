require 'spec_helper'

describe 'monitoring_check::synchronized' do

  let(:title) { 'example1' }
  let('::sensu::check_notify') { 'foo' }

  let(:hiera_data) {{
    'monitoring_check::synchronized::install::redis_server' => 'redis1.example.com',
    'monitoring_check::params::team_data' => { 'qux' => { } },
  }}

  context "by default" do
    let(:params) {{
      :command => 'foo', :runbook => 'y/bar', :source => 'baz',
      :team => 'qux',
    }}
    it { should compile }
  end
  
end
