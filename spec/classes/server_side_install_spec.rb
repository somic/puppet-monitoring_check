require 'spec_helper'

describe 'monitoring_check::server_side::install' do

  context "by default" do
    it {
      should contain_file('/etc/sensu/plugins/check_server_side.rb')
      should contain_file('/etc/sensu/plugins/tiny_redis.rb')
    }
  end
  
end
