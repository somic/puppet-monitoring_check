require 'spec_helper'

describe 'monitoring_check::params' do

  # Assume sensu is being installed to satisfy 'require=>' lines
  let(:pre_condition) { 'package { "sensu": }' }

  context "by default" do
    it { should compile }
    it { should_not contain_file('/etc/facter/facts.d/override_sensu_checks_to.txt') }
    it { should contain_file('/usr/bin/send-test-sensu-alert') }
    it { should have_file_resource_count(2)}
  end
  
  context "When the override_sensu_checks_to fact is present" do
    let(:facts) { { :override_sensu_checks_to => 'test_user' } }
    it { should contain_file('/etc/facter/facts.d/override_sensu_checks_to.txt') }
  end

  context "When given a differnet path for binaries" do
    let(:params) {{ :bin_path => '/special_bin' }}
    it { should contain_file('/special_bin/send-test-sensu-alert') }
    it { should have_file_resource_count(2)}
  end

end
