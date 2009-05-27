require 'spec_helper'

describe "subdomain proc set" do
  before(:each) do
    @proc_set = SubdomainRoutes::ProcSet.new
  end
  
  context "with a subdomain verifier" do
    before(:each) do
      @city_block = Proc.new { |city| [ "boston", "canberra" ].include? city }
      @proc_set.add_verifier(:city, &@city_block)
    end

    it "should indicate what subdomain it verifies" do
      @proc_set.verifies?(:city).should be_true
      @proc_set.verifies?(:user).should be_false
    end
    
    it "should run the verifier" do
      @proc_set.verify(:city, "boston").should be_true
      @proc_set.verify(:city, "hobart").should be_false
    end
  
    it "should return nil if it can't verify the name" do
      @proc_set.verify(:user, "mholling").should be_nil
    end

    it "should call the verify proc only once for multiple verifications" do
      @city_block.should_receive(:call).with("boston").once
      2.times { @proc_set.verify(:city, "boston") }
    end
    
    it "should return the cached value according to the arguments" do
      2.times { @proc_set.verify(:city, "boston").should be_true }
      2.times { @proc_set.verify(:city, "hobart").should be_false }
      2.times { @proc_set.verify(:user, "mholling").should be_nil }
    end
    
    it "should call the verify proc again once the cache is flushed" do
      @city_block.should_receive(:call).with("boston").twice
      5.times { @proc_set.verify(:city, "boston") }
      @proc_set.flush!
      5.times { @proc_set.verify(:city, "boston") }
    end
  end
  
  context "with a generator" do
    before(:each) do
      @proc_set.add_generator(:city) do |options|
        case options[:session][:city_id]
        when 1 then "boston"
        when 2 then "canberra"
        else raise StandardError, "city doesn't exist"
        end
      end
    end
    
    it "should indicate what subdomain it generates" do
      @proc_set.generates?(:city).should be_true
      @proc_set.generates?(:user).should be_false
    end
    
    it "should run the generator" do
      @proc_set.generate(:city, :session => { :city_id => 1 }).should == "boston"
      @proc_set.generate(:city, :session => { :city_id => 2 }).should == "canberra"
    end
    
    it "should raise a routing error if the block raises any error" do
      lambda { @proc_set.generate(:city, {}) }.should raise_error(ActionController::RoutingError)
    end
    
    it "should raise a routing error if it doesn't generate the name" do
      lambda { @proc_set.generate(:user, {}) }.should raise_error(ActionController::RoutingError)
    end
  end
  
  it "can be cleared" do
    @proc_set.add_verifier(:city) { |city| }
    @proc_set.add_generator(:city) { |options| }
    @proc_set.clear!
    @proc_set.verifies?(:city).should be_false
    @proc_set.generates?(:city).should be_false
  end
end