require "#{File.dirname(__FILE__)}/../unit_helper"
require "#{File.dirname(__FILE__)}/../../files/check-cluster"

describe CheckCluster do
  let(:config) do
    { :check        => :test_check,
      :cluster_name => :test_cluster }
  end

  let(:sensu_settings) do
    { :checks => { :test_cluster_test_check => { },
                   :test_check => { } } }
  end

  let(:redis)  { double(:redis) }
  let(:locker) do
    double(:locker).tap do |locker|
      locker.stub(:run).and_yield
    end
  end

  let(:logger) { StringIO.new("") }

  let(:check) do
    CheckCluster.new.tap do |check|
      check.stub(
        :config         => config,
        :sensu_settings => sensu_settings,
        :redis          => redis,
        :locker         => locker,
        :logger         => logger)

      check.stub(:api_request).
        with("/aggregates/test_check", {:age=>30}).
        and_return([1, 2, 3])

      check.stub(:api_request).
        with("/aggregates/test_check/3").
        and_return('ok' => 1, 'total' => 1)
    end
  end

  def expect_ok(message)
    expect(check).to receive(:ok)
    expect(check).to receive(:send_payload).with(0, message).and_return(nil)

    # spec hack, original #ok method calls Kernel.exit but stubbed one doesn't
    expect(check).to receive(:unknown)
  end

  context "status" do
    context "should be OK" do
      it "when all is good" do
        expect_ok "Aggregate looks GOOD"
        check.run
      end

      it "when check locked"
      it "when lock slipped"
    end

    context "should be WARNING" do
      it "when lock expired"
    end

    context "should be CRITICAL" do
      it "when exception happened"
    end

    context "should be UNKNOWN" do
      it "when no status was reported"
      it "when wrong version of sensu"
    end
  end

  context "payload" do
    context "should be OK" do
      it "when all is good"
    end

    context "should be WARNING" do
      it "when no old-enough aggregates"
      it "when reached warning threshold"
    end

    context "should be CRITICAL" do
      it "when reached critical threshold"
    end

    context "should be UNKNOWN" do
      # nothing?
    end
  end

  # implementation details
  it "should run within a lock" do
    expect_ok "Aggregate looks GOOD"
    expect(locker).to receive(:run)
    check.run
  end
end
