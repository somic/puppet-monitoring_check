require "#{File.dirname(__FILE__)}/../unit_helper"
require "#{File.dirname(__FILE__)}/../../files/check_server_side"

describe CheckServerSide do

  let(:settings) do
    {
      'checks' => {
        'check_foo' => {
          'interval' => 100,
          'actual_command' => 'true',
        },
      }
    }
  end

  let(:redis) do
    double(:redis).tap do |redis|
      redis.stub(
        :echo    => 'hello',
        :setnx   => 1,
        :pexpire => 1,
        :ttl     => 100,
      )
    end
  end

  let(:check) do
    CheckServerSide.new.tap do |check|
      check.stub(
        :settings => settings,
        :redis    => redis,
        :config   => { :check => 'check_foo' },
        :send_new_check_event_to_local_sensu_client => true,
        :expect   => Proc.new do |code, msg|
                       expect(self).to receive(code).with(msg)
                       self.run
                     end,
      )
    end
  end

  context "when unknown exception occurs" do
    let(:settings) {{ }} # this will cause at least some exception
    it "swallows the exception and returns ok" do
      check.expect :ok, /ran actual check: exception/
    end
  end

  context "when unable to get a lock" do
    it "skips the check and returns ok" do
      redis.stub(:setnx).and_return 0
      check.expect :ok, /skipped actual check: lock detected/
    end
  end

  context "when lock was obtained" do
    it "runs the check and returns ok" do
      check.expect :ok, /ran actual check: exit_code=0/
    end
  end

end
