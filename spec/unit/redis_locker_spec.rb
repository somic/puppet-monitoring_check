require "#{File.dirname(__FILE__)}/../unit_helper"
require "#{File.dirname(__FILE__)}/../../files/check-cluster"

describe RedisLocker do
  let(:interval) { 10 }

  let(:now)      { Time.now.to_i }
  let(:locked)   { now - interval / 2 }
  let(:expired)  { now - interval - 1 }

  let(:log)    { Logger.new(StringIO.new("")) }
  let(:key)    { "key" }
  let(:status) { double(:status) }
  let(:redis)  { double(:redis) }
  let(:locker) { RedisLocker.new(status, redis, key, interval, now, log) }

  def setup_mocks
    redis.stub(
      :echo    => "hello",
      :setnx   => 1,
      :pexpire => 1,
      :get     => 1)

    status.stub(
      :ok       => true,
      :warning  => true,
      :critical => true,
      :unknown  => true)
  end

  before(:each) { setup_mocks }

  context "when lock can be acquired" do
    it "should run the block" do
      expect { |b| locker.run(&b) }.to yield_control
    end

    it "should lock and expire" do
      expect(locker).to receive(:expire).with(10)
      locker.run { }
    end

    it "should clear lock upon error" do
      expect(locker).to receive(:expire).with(10)
      expect(locker).to receive(:expire).with
      expect(status).to receive(:critical)
      expect { locker.run { raise "fail" } }.to raise_error
    end
  end

  context "when check is locked" do
    it "should report ok" do
      redis.stub(:setnx).and_return(0)
      redis.stub(:get).and_return(locked)
      expect(status).to receive(:ok).with(/expires/)
      locker.run { }
    end
  end

  context "when check expired between setnx and get" do
    it "should report ok" do
      redis.stub(:setnx).and_return(0)
      redis.stub(:get).and_return(nil)
      expect(status).to receive(:ok).with(/problem/)
      locker.run { }
    end
  end

  context "when check locked but expired" do
    it "should report ok" do
      redis.stub(:setnx).and_return(0)
      redis.stub(:get).and_return(expired)
      expect(status).to receive(:ok).with(/problem/)
      locker.run { }
    end
  end
end
