require "#{File.dirname(__FILE__)}/../unit_helper"
require "#{File.dirname(__FILE__)}/../../files/check-cluster"

describe CheckCluster do
  context "status" do
    context "should be OK" do
      it "when all is good"
    end

    context "should be WARNING"
    context "should be CRITICAL"
    context "should be UNKNOWN" do
      it "when no status was reported"
    end
  end

  context "payload" do
    context "should be OK" do
      it "when all is good"
      it "when lock slipped"
      it "when check is locked"
    end

    context "should be WARNING" do
      it "when no old-enough aggregates"
      it "when lock is expired"
      it "when reached warning threshold"
    end

    context "should be CRITICAL" do
      it "when exception happened"
      it "when reached critical threshold"
      it ""
    end

    context "should be UNKNOWN" do

    end
  end

  # implementation details
  it "should run within a lock"
end
