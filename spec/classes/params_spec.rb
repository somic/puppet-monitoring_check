require 'spec_helper'

describe 'monitoring_check::params' do

  context "by default" do
    let(:facts) { { :lsbdistid => 'Ubuntu', :osfamily => 'Debian', :lsbdistcodename => 'lucid', :operatingsystem => 'Ubuntu', :ipaddress => '127.0.0.1', :puppetversion => '3.6.2' } }
    it { should compile }
    it { should_not contain_file('/etc/facter/facts.d/override_sensu_checks_to.txt') }
  end
  
  context "When the override_sensu_checks_to fact is present" do
    let(:facts) { { :lsbdistid => 'Ubuntu', :osfamily => 'Debian', :lsbdistcodename => 'lucid', :operatingsystem => 'Ubuntu', :ipaddress => '127.0.0.1', :puppetversion => '3.6.2', :override_sensu_checks_to => 'test_user' } }
    it { should contain_file('/etc/facter/facts.d/override_sensu_checks_to.txt') }
  end

end
