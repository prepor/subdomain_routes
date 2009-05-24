require 'spec_helper'

describe SubdomainRoutes do
  before(:each) do
    ActionController::Routing::Routes.clear!
    SubdomainRoutes::Config.stub!(:domain_length).and_return(2)
  end
  
  describe "resources routes" do
    it "should pass the specified subdomains to any nested routes" do
      map_subdomain(:admin) do |admin|
        admin.resources(:items) { |item| item.options[:subdomains].should == [ :admin ] }
        admin.resource(:config) { |config| config.options[:subdomains].should == [ :admin ] }
      end
    end
  end
end
