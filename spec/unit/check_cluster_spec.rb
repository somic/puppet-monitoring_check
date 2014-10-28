require "#{File.dirname(__FILE__)}/../unit_helper"
require "#{File.dirname(__FILE__)}/../../files/check-cluster"

describe CheckCluster do
  let(:config) do
    { :check        => :test_check,
      :cluster_name => :test_cluster,
      :warning      => 30,
      :critical     => 50 }
  end

  let(:sensu_settings) do
    { :checks => { :test_cluster_test_check => { },
                   :test_check => { } },
      :api => { :host => 'localhost',
                :port => '9999' } }
  end

  let(:redis)  do
    double(:redis).tap do |redis|
      redis.stub(
        :echo    => "hello",
        :setnx   => 1,
        :pexpire => 1,
        :get     => Time.now.to_i - 5)
    end
  end

  let(:logger) { StringIO.new("") }

  let(:api) do
    double(:api).tap do |api|
      api.stub(:request).
        with("/aggregates/test_check", {:age=>30}).
        and_return([1, 2, 3])

      api.stub(:request).
        with("/aggregates/test_check/3").
        and_return('ok' => 1, 'total' => 1)
    end
  end

  let(:check) do
    CheckCluster.new.tap do |check|
      check.stub(
        :config         => config,
        :sensu_settings => sensu_settings,
        :redis          => redis,
        :logger         => logger,
        :api            => api,
        :unknown        => nil)
    end
  end

  def expect_status(code, message)
    expect(check).to receive(code).with(message)
  end

  def expect_payload(code, message)
    expect(check).to receive(:send_payload).with(
      Sensu::Plugin::EXIT_CODES[code.to_s.upcase], message).and_return(nil)
  end

  context "status" do
    context "should be OK" do
      it "when all is good" do
        expect_status :ok, "Check executed successfully"
        expect_payload :ok, "Aggregate looks GOOD"
        check.run
      end

      it "when check locked" do
        redis.stub(:setnx).and_return 0
        expect_status :ok, /Lock expires in/
        check.run
      end

      it "when lock slipped" do
        redis.stub(:setnx).and_return 0
        redis.stub(:get).and_return nil
        expect_status :ok, /slip/
        check.run
      end
    end

    context "should be WARNING" do
      it "when lock expired" do
        redis.stub(:setnx).and_return 0
        redis.stub(:get).and_return 0
        expect_status :warning, /expired/
        check.run
      end
    end

    context "should be CRITICAL" do
      it "when exception happened" do
        expect(redis).to receive(:setnx).and_raise "rspec error"
        expect_status :critical, /rspec error/
        check.run
      end
    end

    context "should be UNKNOWN" do
      it "when no status was reported" do
        expect_status :unknown, "Check didn't report status"
        check.stub(:locked_run).and_return nil
        check.run
      end

      it "when wrong version of sensu" do
        stub_const("Sensu::VERSION", "0.12")
        expect_status :unknown, "Sensu <0.13 is not supported"
        check.stub(:locked_run).and_return nil
        check.run
      end
    end
  end

  context "payload" do
    context "should be WARNING" do
      it "when no old-enough aggregates" do
        expect(api).to receive(:request).
          with("/aggregates/test_check", {:age=>30}).and_return([])

        expect(check.send :check_aggregate).to(
          eq([1, "No aggregates older than 30 seconds"]))
      end

      it "when reached warning threshold" do
        check.send(:check_thresholds, 'ok' => 60, 'total' => 100) do |status, message|
          expect(status).to be(1)
          expect(message).to match(/40%/)
        end
      end
    end

    context "should be CRITICAL" do
      it "when reached critical threshold" do
        check.send(:check_thresholds, 'ok' => 40, 'total' => 100) do |status, message|
          expect(status).to be(2)
          expect(message).to match(/60%/)
        end
      end
    end
  end

  # implementation details
  it "should run within a lock" do
    expect(redis).to receive(:setnx).and_return(1)
    expect_status :ok, "Check executed successfully"
    expect_payload :ok, "Aggregate looks GOOD"
    check.run
  end

  it "should check_thresholds within check_aggregate" do
    expect(check).to receive(:check_thresholds)
    check.send :check_aggregate
  end
end
