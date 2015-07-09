require "#{File.dirname(__FILE__)}/../unit_helper"
require "#{File.dirname(__FILE__)}/../../files/tiny_redis"

describe TinyRedis::Mutex do
  let(:interval) { 10 }

  let(:now)      { Time.now.to_i }
  let(:locked)   { now - interval / 2 }
  let(:expired)  { now - interval - 1 }

  let(:log)    { StringIO.new("") }
  let(:key)    { "key" }
  let(:redis)  { double(:redis) }
  let(:locker) { TinyRedis::Mutex.new(redis, key, interval, log) }

  def setup_mocks
    redis.stub(
      :echo    => "hello",
      :setnx   => 1,
      :pexpire => 1,
      :get     => 1)
  end

  before(:each) { setup_mocks }

  describe '#ttl' do
    it 'is nil when no expiration' do
      redis.stub(:pttl => nil)
      expect(locker.ttl).to be_nil
    end

    it 'returns amount in seconds' do
      redis.stub(:pttl => 1234)
      expect(locker.ttl).to eq(1.234)
    end
  end

  context "when lock can be acquired" do
    it "should run_with_lock_or_skip the block" do
      expect { |b| locker.run_with_lock_or_skip(&b) }.to yield_control
    end

    it "should lock and expire" do
      expect(locker).to receive(:expire).with(10)
      locker.run_with_lock_or_skip { }
    end

    it "should clear lock upon error" do
      expect(locker).to receive(:expire).with(10)
      expect(locker).to receive(:expire).with
      expect { locker.run_with_lock_or_skip { raise "fail" } }.to raise_error
    end
  end

  context "when check is locked" do
    it "should report ok" do
      redis.stub(:setnx).and_return(0)
      redis.stub(:get).and_return(locked)
      locker.run_with_lock_or_skip { }
    end
  end

  context "when check expired between setnx and get" do
    it "should report ok" do
      redis.stub(:setnx).and_return(0)
      redis.stub(:get).and_return(nil)
      locker.run_with_lock_or_skip { }
    end
  end

  context "when check locked but expired" do
    it "should report ok" do
      redis.stub(:setnx).and_return(0)
      redis.stub(:get).and_return(expired)
      locker.run_with_lock_or_skip { }
    end
  end
end
