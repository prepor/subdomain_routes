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
  
  context "with a generator proc" do
    before(:each) do
      @request = ActionController::TestRequest.new
    end
  
    it "should raise a routing error if it doesn't generate the name" do
      lambda { @proc_set.generate(:user, nil, nil) }.should raise_error(ActionController::RoutingError)
    end
    
    context "taking one argument" do
      before(:each) do
        @block = lambda { |request| } # this generator block will be stubbed
        @proc_set.add_generator(:city, &@block)
      end
    
      it "should indicate what subdomain it generates" do
        @proc_set.generates?(:city).should be_true
        @proc_set.generates?(:user).should be_false
      end
    
      it "should pass the request to the generator proc" do
        @block.should_receive(:call).with(@request).and_return("boston")
        @proc_set.generate(:city, @request, nil).should == "boston"
      end
    
      it "should raise a routing error if the proc raises any error" do
        @block.should_receive(:call).with(@request).and_raise(StandardError.new)
        lambda { @proc_set.generate(:city, @request, nil) }.should raise_error(ActionController::RoutingError)
      end

      it "should raise a routing error if a nil request is supplied" do
        lambda { @proc_set.generate(:city, nil, nil) }.should raise_error(ActionController::RoutingError)
      end
    end

    context "taking two arguments" do
      before(:each) do
        @block = lambda { |request, context| } # this generator block will be stubbed
        @proc_set.add_generator(:city, &@block)
        @context = { :city_id => 2 }
      end
    
      it "should pass the request and the context to the generator proc" do
        @block.should_receive(:call).with(@request, @context).and_return("boston")
        @proc_set.generate(:city, @request, @context).should == "boston"
      end
    
      it "should raise a routing error if the block raises any error" do
        @block.should_receive(:call).with(@request, @context).and_raise(StandardError.new)
        lambda { @proc_set.generate(:city, @request, @context) }.should raise_error(ActionController::RoutingError)
      end

      it "should not raise a routing error if a nil request is supplied" do
        lambda { @proc_set.generate(:city, nil, nil) }.should_not raise_error
      end
    end
  end
  
  it "can be cleared" do
    @proc_set.add_verifier(:city) { |city| }
    @proc_set.add_generator(:city) { |request| }
    @proc_set.clear!
    @proc_set.verifies?(:city).should be_false
    @proc_set.generates?(:city).should be_false
  end
end