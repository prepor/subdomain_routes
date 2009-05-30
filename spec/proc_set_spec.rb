require 'spec_helper'

describe "subdomain proc set" do
  before(:each) do
    @proc_set = SubdomainRoutes::ProcSet.new
  end
  
  context "with a subdomain recognizer" do
    before(:each) do
      @city_block = lambda { |city| } # this recognizer block will be stubbed out
      @proc_set.add_recognizer(:city, &@city_block)
    end

    it "should indicate what subdomain it recognizes" do
      @proc_set.recognizes?(:city).should be_true
      @proc_set.recognizes?(:user).should be_false
    end
    
    it "should run the recognizer" do
      @city_block.should_receive(:call).with("boston").and_return(true)
      @proc_set.recognize(:city, "boston").should == true
    end
    
    it "should raise any error that the recognizer raises" do
      error = StandardError.new
      @city_block.stub!(:call).and_raise(error)
      lambda { @proc_set.recognize(:city, "hobart") }.should raise_error { |e| e.should == error }
    end
  
    it "should return nil if it can't recognize the name" do
      @proc_set.recognize(:user, "mholling").should be_nil
    end

    it "should call the recognize proc only once for multiple recognitions" do
      @city_block.should_receive(:call).with("boston").once
      2.times { @proc_set.recognize(:city, "boston") }
    end
    
    it "should return the cached value according to the arguments" do
      @city_block.should_receive(:call).with("boston").once.and_return(true)
      @city_block.should_receive(:call).with("hobart").once.and_return(false)
      2.times do
        @proc_set.recognize(:city, "boston").should == true
        @proc_set.recognize(:city, "hobart").should == false
      end
    end
    
    it "should call the recognize proc again once the cache is flushed" do
      @city_block.should_receive(:call).with("boston").twice
      5.times { @proc_set.recognize(:city, "boston") }
      @proc_set.flush!
      5.times { @proc_set.recognize(:city, "boston") }
    end
  end
  
  it "can be cleared of its procs" do
    @proc_set.add_recognizer(:city) { |city| }
    @proc_set.clear!
    @proc_set.recognizes?(:city).should be_false
  end
end