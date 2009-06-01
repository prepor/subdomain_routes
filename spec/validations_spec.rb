describe "ActiveRecord::Base" do
  it "should have validates_subdomain_format_of which runs SubdomainRoutes.valid_subdomain? against the attributes" do
    class User < ActiveRecord::Base
      attr_accessor :subdomain
      User.validates_subdomain_format_of :subdomain
    end
    SubdomainRoutes.should_receive(:valid_subdomain?).with("mholling").and_return(true)
    User.new(:subdomain => "mholling").valid?.should be_true
    SubdomainRoutes.should_receive(:valid_subdomain?).with("mholling").and_return(nil)
    User.new(:subdomain => "mholling").valid?.should be_false
  end
  
  # it "should have a validates_subdomain_not_reserved"
end
