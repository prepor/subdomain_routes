require 'spec_helper'

describe SubdomainRoutes do
  before(:each) do
    ActionController::Routing::Routes.clear!
  end
  
  describe "subdomain extraction" do
    include SubdomainRoutes::SplitHost

    describe "configuration" do
      it "should have a default domain length of 2" do
        SubdomainRoutes::Config.domain_length.should == 2
      end
    end
    
    it "should find the domain" do
      domain_for_host("www.example.com").should == "example.com"
    end

    it "should find the subdomain when it is present" do
      subdomain_for_host("www.example.com").should == "www"
    end
  
    it "should find nil when subdomain is absent" do
      subdomain_for_host("example.com").should be_nil
    end
    
    context "with multi-level subdomains" do
      before(:each) do
        @host = "blah.www.example.com"
      end
      
      it "should raise an error" do
        lambda { subdomain_for_host(@host) }.should raise_error(SubdomainRoutes::TooManySubdomains)
      end
            
      it "should raise an error when generating URLs" do
        map_subdomain(:admin) { |admin| admin.resources :users }
        with_host(@host) do
          lambda { admin_users_path }.should raise_error(SubdomainRoutes::TooManySubdomains)
        end
      end
      
      it "should raise an error when recognising URLs" do
        request = ActionController::TestRequest.new
        request.host = @host
        lambda { recognize_path(request) }.should raise_error(SubdomainRoutes::TooManySubdomains)
      end
    end
  
    it "should add a subdomain method to requests" do
      request = ActionController::TestRequest.new
      request.host = "admin.example.com"
      request.subdomain.should == "admin"
    end
  end
end
