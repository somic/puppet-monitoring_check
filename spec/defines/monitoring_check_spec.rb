require 'spec_helper'

describe 'monitoring_check' do

  # Use let! to force the function to be initialize before it is lazily loaded
  let!(:annotation_guess) { MockFunction.new('annotation_guess') { |f|
      f.stubs(:call).with([]).returns('mock_annotation')
    }
  }

  context 'without teams data' do
    let(:title) { 'examplecheck' }
    let(:hiera_data) { { :sensu_enabled => true, :'sensu_handlers::teams' => { } } }
    let(:facts) { { :lsbdistid => 'Ubuntu', :osfamily => 'Debian', :lsbdistcodename => 'lucid', :operatingsystem => 'Ubuntu', :ipaddress => '127.0.0.1', :puppetversion => '3.6.2' } }

    let(:default_interval) { 60 }
    let(:params) { {:command => 'bar', :runbook => 'http://gronk', :page => true} }
      it do
        expect {
          should compile
        }.to raise_error(Puppet::Error, /No sensu_handlers::teams/)
      end
  end
  context 'with teams data' do
    let(:title) { 'examplecheck' }
    let(:hiera_data) { { :sensu_enabled => true, :'sensu_handlers::teams' => { 'operations' => {}, 'other' => {}} } }
    let(:facts) { { :lsbdistid => 'Ubuntu', :osfamily => 'Debian', :lsbdistcodename => 'lucid', :operatingsystem => 'Ubuntu', :ipaddress => '127.0.0.1', :puppetversion => '3.6.2' } }

    let(:default_interval) { 60 }

    context "basic test" do
      let(:params) { {:command => 'bar', :runbook => 'http://gronk', :page => true} }
      it do
        should contain_sensu__check('examplecheck') \
          .with_ensure('present') \
          .with_handlers('default') \
          .with_interval(default_interval) \
          .with_command('bar') \
          .with_custom({
            "runbook"=>"http://gronk",
            "dependencies"=>[],
            "ticket"=>false,
            "irc_channels"=>:undef,
            "tip"=>false,
            "project"=>false,
            "alert_after"=>"0",
            "page"=>true,
            "annotation"=>"mock_annotation",
            "realert_every"=>"-1",
            "sla"=>"No SLA defined.",
            "team"=>"operations",
            "notification_email"=>"undef"
          })
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
      it { should contain_sensu__check('examplecheck').with_custom({
        "runbook"=>"http://gronk",
        "dependencies"=>[],
        "ticket"=>false,
        "irc_channels"=>:undef,
        "tip"=>false,
        "project"=>false,
        "alert_after"=>"0",
        "page"=>false,
        "realert_every"=>"-1",
        "sla"=>"No SLA defined.",
        "team"=>"other",
        "annotation"=>"mock_annotation",
        "notification_email"=>"undef"})
      }
    end

    context "custom team (nonexistent)" do
      let(:params) { {:command => 'bar', :runbook => 'http://gronk', :team => 'doesnotexist'} }
      it do
        expect { should contain_monitoring_check('examplecheck') }.to raise_error(Exception, /does not match/)
      end
    end
    context "with one dependency" do
      let(:params) { {:command => 'bar', :runbook => 'http://gronk', :dependencies => 'dep1'} }
      it { should contain_sensu__check('examplecheck').with_custom({
        "runbook"=>"http://gronk",
        "dependencies"=>["dep1"],
        "ticket"=>false,
        "irc_channels"=>:undef,
        "tip"=>false,
        "project"=>false,
        "alert_after"=>"0",
        "page"=>false,
        "realert_every"=>"-1",
        "sla"=>"No SLA defined.",
        "team"=>"operations",
        "notification_email"=>"undef",
        "annotation"=>"mock_annotation"})
      }
    end

    context "with two dependency" do
      let(:params) { {:command => 'bar', :runbook => 'http://gronk', :dependencies => ['dep1', 'dep2']} }
      it { should contain_sensu__check('examplecheck').with_custom({
        "runbook"=>"http://gronk",
        "dependencies"=> ["dep1","dep2"],
        "ticket"=>false,
        "irc_channels"=>:undef,
        "tip"=>false,
        "project"=>false,
        "alert_after"=>"0",
        "page"=>false,
        "realert_every"=>"-1",
        "sla"=>"No SLA defined.",
        "team"=>"operations",
        "notification_email"=>"undef",
        "annotation"=>"mock_annotation"
      })}
    end

    context "with custom" do
      let(:params) { {:command => 'bar', :runbook => 'http://gronk', :sensu_custom => { 'foo' => 'bar' } } }
      it { should contain_sensu__check('examplecheck').with_custom({
          "runbook"=>"http://gronk",
          "dependencies"=>[],
          "ticket"=>false,
          "irc_channels"=>:undef,
          "tip"=>false,
          "project"=>false,
          "alert_after"=>"0",
          "foo"=>"bar",
          "page"=>false,
          "realert_every"=>"-1",
          "sla"=>"No SLA defined.",
          "team"=>"operations",
          "notification_email"=>"undef",
          "annotation"=>"mock_annotation"
        }
      )}
    end

    context "with custom - overriding" do
      let(:params) { {:command => 'bar', :runbook => 'http://gronk', :sensu_custom => { 'team' => 'overridden' } } }
      it { should contain_sensu__check('examplecheck').with_custom({
        "runbook"=>"http://gronk",
        "dependencies"=>[],
        "ticket"=>false,
        "irc_channels"=>:undef,
        "tip"=>false,
        "project"=>false,
        "alert_after"=>"0",
        "page"=>false,
        "realert_every"=>"-1",
        "sla"=>"No SLA defined.",
        "team"=>"overridden",
        "notification_email"=>"undef",
        "annotation"=>"mock_annotation"
        }
      )}
    end

    context "nowake, nopage" do
      let(:params) { {:command => 'bar', :runbook => 'http://gronk', :page => 'false'} }
      it { should contain_sensu__check('examplecheck').with_custom({
          "runbook"=>"http://gronk",
          "dependencies"=>[],
          "ticket"=>false,
          "irc_channels"=>:undef,
          "tip"=>false,
          "project"=>false,
          "alert_after"=>"0",
          "page"=>false,
          "realert_every"=>"-1",
          "sla"=>"No SLA defined.",
          "team"=>"operations",
          "annotation"=>"mock_annotation",
          "notification_email"=>"undef"
        }
      )}
    end

    context "With a SLA defined" do
      let(:params) { {:command => 'bar', :runbook => 'http://gronk', :page => 'false', :sla=>'custom SLA'} }
      it { should contain_sensu__check('examplecheck').with_custom({
          "runbook"=>"http://gronk",
          "dependencies"=>[],
          "ticket"=>false,
          "irc_channels"=>:undef,
          "tip"=>false,
          "project"=>false,
          "alert_after"=>"0",
          "page"=>false,
          "realert_every"=>"-1",
          "sla"=>"custom SLA",
          "team"=>"operations",
          "annotation"=>"mock_annotation",
          "notification_email"=>"undef"
        }
      )}
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
    context "sudo with a non qualified command" do
      let(:params) { {:command => 'bar --foo --baz', :runbook => 'http://gronk', :needs_sudo => true, :sudo_user => 'fred'} }
      it { expect { should compile }.to raise_error() }
    end

    context "Aggregate Checks" do
      let(:params) { {:aggregate => true, :command => 'bar', :runbook => 'y/gronk'} }
      it { should contain_sensu__check('examplecheck').with_handle(false) }
      it { should contain_sensu__check('examplecheck').with_aggregate(true) }
    end
    context "Non Aggregate Checks" do
      let(:params) { { :command => 'bar', :runbook => 'y/gronk'} }
      it { should contain_sensu__check('examplecheck').with_handle(true) }
      it { should contain_sensu__check('examplecheck').with_aggregate(false) }
    end

    context "check with timeout" do
      let(:params) { { :command => 'bar', :runbook => 'y/gronk', :check_every => '5m', :timeout => 50 } }
      it { should contain_sensu__check('examplecheck').with_timeout(50) }
    end

    context "check default timeout" do
      let(:params) { { :command => 'bar', :runbook => 'y/gronk', :check_every => '5m' } }
      it { should contain_sensu__check('examplecheck').with_timeout(300) }
    end

    context "check default timeout for long period checks" do
      let(:params) { { :command => 'bar', :runbook => 'y/gronk', :check_every => '5h' } }
      it { should contain_sensu__check('examplecheck').with_timeout(3600) }
    end

  end

end


