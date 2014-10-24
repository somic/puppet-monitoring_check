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

  let(:check) do
    CheckCluster.new.tap do |check|
      check.stub(
        :config         => config,
        :sensu_settings => sensu_settings,
        :redis          => redis,
        :logger         => logger,
        :unknown        => nil)

      check.stub(:api_request).
        with("/aggregates/test_check", {:age=>30}).
        and_return([1, 2, 3])

      check.stub(:api_request).
        with("/aggregates/test_check/3").
        and_return('ok' => 1, 'total' => 1)
    end
  end

  def expect_status(code, message)
    expect(check).to receive(code)
  end

  def expect_payload(code, message)
    expect(check).to receive(:send_payload).with(
      Sensu::Plugin::EXIT_CODES[code.to_s.upcase], message).and_return(nil)
  end

  context "status" do
    context "should be OK" do
      it "when all is good" do
        expect_status :ok, "Aggregate looks GOOD"
        expect_payload :ok, "Aggregate looks GOOD"
        check.run
      end

      it "when check locked" do
        redis.stub(:setnx).and_return 0
        expect_status :ok, "123"
        check.run
      end

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
    expect(redis).to receive(:setnx).and_return(1)
    expect_status :ok, "Aggregate looks GOOD"
    expect_payload :ok, "Aggregate looks GOOD"
    check.run
  end
end
