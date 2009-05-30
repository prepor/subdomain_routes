describe "ActiveRecord::Base" do
  it "should have validates_subdomain_format_of which runs SubdomainRoutes.valid_subdomain? against the attributes" do
    class User < ActiveRecord::Base
      attr_accessor :subdomain
      User.validates_subdomain_format_of :subdomain
    end
    [ true, false ].each do |value|
      SubdomainRoutes.should_receive(:valid_subdomain?).with("mholling").and_return(value)
      User.new(:subdomain => "mholling").valid?.should == value
    end
  end
end