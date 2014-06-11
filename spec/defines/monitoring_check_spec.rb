require 'spec_helper'

describe 'monitoring_check' do
  let(:title) { 'examplecheck' }
  let(:hiera_data) { { :sensu_enabled => true, :'monitoring::teams' => { 'operations' => {}, 'other' => {}} } }
  let(:facts) { { :osfamily => 'Debian', :lsbdistcodename => 'lucid', :operatingsystem => 'Ubuntu' } }

  let(:default_interval) { 5*60 }

  context "basic test" do
    let(:params) { {:command => 'bar', :runbook => 'http://gronk', :page => true} }
    it do
      should contain_sensu__check('examplecheck') \
        .with_ensure('present') \
        .with_handlers('default') \
        .with_interval(default_interval) \
        .with_command('bar') \
        .with_custom({ "dependencies"=>[], "runbook"=>"http://gronk", "irc_channels"=>:undef, "realert_every"=>"1", "alert_after"=>"0", "tip"=>false, "page"=>true, "team"=>"operations", "notification_email"=>:undef })
    end
  end
  context "bad runbook (not a uri)" do
    let(:params) { {:command => 'bar', :runbook => 'gronk'} }
    it do
      expect { should contain_monitoring_check('examplecheck') }.to raise_error(Exception, /does not match/)
    end
  end
  context "custom team" do
    let(:params) { {:command => 'bar', :runbook => 'http://gronk', :team => 'other'} }
    it { should contain_sensu__check('examplecheck').with_custom({"dependencies"=>[], "runbook"=>"http://gronk", "irc_channels"=>:undef, "alert_after"=>"0", "tip"=>false, "page"=>false, "realert_every"=>"1", "team"=>"other", "notification_email"=>:undef }) }
  end
  context "custom team (nonexistent)" do
    let(:params) { {:command => 'bar', :runbook => 'http://gronk', :team => 'doesnotexist'} }
    it do
      expect { should contain_monitoring_check('examplecheck') }.to raise_error(Exception, /does not match/)
    end
  end
  context "with one dependency" do
    let(:params) { {:command => 'bar', :runbook => 'http://gronk', :dependencies => 'dep1'} }
    it { should contain_sensu__check('examplecheck').with_custom({"dependencies"=>["dep1"], "runbook"=>"http://gronk", "irc_channels"=>:undef, "alert_after"=>"0", "tip"=>false, "page"=>false, "realert_every"=>"1", "team"=>"operations" , "notification_email"=>:undef }) }
  end
  context "with two dependency" do
    let(:params) { {:command => 'bar', :runbook => 'http://gronk', :dependencies => ['dep1', 'dep2']} }
    it { should contain_sensu__check('examplecheck').with_custom({"dependencies"=>["dep1", "dep2"], "runbook"=>"http://gronk", "irc_channels"=>:undef, "alert_after"=>"0", "tip"=>false, "page"=>false, "realert_every"=>"1", "team"=>"operations", "notification_email"=>:undef }) }
  end

  context "with custom" do
    let(:params) { {:command => 'bar', :runbook => 'http://gronk', :sensu_custom => { 'foo' => 'bar' } } }
    it { should contain_sensu__check('examplecheck').with_custom({"dependencies"=>[], "runbook"=>"http://gronk", "irc_channels"=>:undef, "alert_after"=>"0", "tip"=>false, "page"=>false, "foo"=>"bar", "realert_every"=>"1", "team"=>"operations", "notification_email"=>:undef }) }
  end
  context "with custom - overriding" do
    let(:params) { {:command => 'bar', :runbook => 'http://gronk', :sensu_custom => { 'team' => 'overridden' } } }
    it { should contain_sensu__check('examplecheck').with_custom({"dependencies"=>[], "runbook"=>"http://gronk", "irc_channels"=>:undef, "alert_after"=>"0", "tip"=>false, "page"=>false, "realert_every"=>"1","team"=>"overridden", "notification_email"=>:undef })}
  end
  context "nowake, nopage" do
    let(:params) { {:command => 'bar', :runbook => 'http://gronk', :page => 'false'} }
    it { should contain_sensu__check('examplecheck').with_custom({"dependencies"=>[], "runbook"=>"http://gronk", "irc_channels"=>:undef, "alert_after"=>"0", "tip"=>false, "page"=>false, "realert_every"=>"1", "team"=>"operations", "notification_email"=>:undef }) }
  end

  context "sudo" do
    let(:params) { {:command => '/bin/bar --foo --baz', :runbook => 'http://gronk', :needs_sudo => true, :sudo_user => 'fred'} }
    it do
      should contain_sensu__check('examplecheck') \
        .with_command('sudo -H -u fred -- /bin/bar --foo --baz')
      should contain_sudo__conf("sensu_examplecheck") \
        .with_content("sensu       ALL=(fred) NOPASSWD: /bin/bar\nDefaults!/bin/bar !requiretty")
    end
  end
end


