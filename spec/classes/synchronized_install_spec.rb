require 'spec_helper'

describe 'monitoring_check::synchronized::install' do

  let(:hiera_data) {{
    'monitoring_check::synchronized::install::redis_server' => 'redis1.example.com',
  }}

  context "by default" do
    it {
      should contain_file('/etc/sensu/plugins/check-synchronized.rb')
      should contain_file('/etc/sensu/plugins/lib/tiny_redis.rb')
      should contain_file('/etc/sensu/conf.d/synchronized.json') \
               .with_content(/redis1.example.com/)
    }
  end
  
end
