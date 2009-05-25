require 'spec_helper'

describe SubdomainRoutes do
  before(:each) do
    ActionController::Routing::Routes.clear!
    SubdomainRoutes::Config.stub!(:domain_length).and_return(2)
  end
  
  describe "route recognition" do
    before(:each) do
      @request = ActionController::TestRequest.new
      @request.host = "www.example.com"
      @request.request_uri = "/items/2"
    end
  
    it "should add the host's subdomain to the request environment" do
      request_environment = ActionController::Routing::Routes.extract_request_environment(@request)
      request_environment[:subdomain].should == "www"
    end
    
    it "should add a nil subdomain to the request environment if the host has no subdomain" do
      @request.host = "example.com"
      request_environment = ActionController::Routing::Routes.extract_request_environment(@request)
      request_environment[:subdomain].should be_nil
    end
    
    context "for a single specified subdomain" do
      it "should recognise a route if the subdomain matches" do
        map_subdomain(:www) { |www| www.resources :items }
        params = recognize_path(@request)
        params[:controller].should == "www/items"
        params[:action].should == "show"
        params[:id].should == "2"
      end
    
      it "should not recognise a route if the subdomain doesn't match" do
        map_subdomain("admin") { |admin| admin.resources :items }
        lambda { recognize_path(@request) }.should raise_error(ActionController::RoutingError)
      end
    end
    
    context "for a nil subdomain" do
      it "should recognise a route if there is no subdomain" do
        map_subdomain(nil) { |map| map.resources :items }
        @request.host = "example.com"
        params = recognize_path(@request)
        params[:controller].should == "items"
        params[:action].should == "show"
        params[:id].should == "2"
      end
    end
    
    context "for multiple specified subdomains" do
      it "should recognise a route if the subdomain matches" do
        map_subdomain(:www, :admin, :name => nil) { |map| map.resources :items }
        params = recognize_path(@request)
        params[:controller].should == "items"
        params[:action].should == "show"
        params[:id].should == "2"
      end
    
      it "should not recognise a route if the subdomain doesn't match" do
        map_subdomain(:support, :admin, :name => nil) { |map| map.resources :items }
        lambda { recognize_path(@request) }.should raise_error(ActionController::RoutingError)
      end
    end
    
    context "for a proc subdomain" do
      before(:each) do
        map_subdomain(:proc => :blog?) { |blog| blog.resources :articles }
        
        @request = ActionController::TestRequest.new
        @request.request_uri = "/articles"
        
        SubdomainRoutes::Config.subdomain_proc :blog? do |subdomain|
          case subdomain
          when "recognised" then true
          when "redirect" then :www
          else false
          end
        end
      end
      
      it "should match the route if the proc returns true" do
        @request.host = "recognised.example.com"
        lambda { recognize_path(@request) }.should_not raise_error
      end
      
      it "should not match the route if the proc returns a different subdomain" do
        @request.host = "redirect.example.com".sub(/^\./, '')
        lambda { recognize_path(@request) }.should raise_error(ActionController::RoutingError)
      end
      
      it "should not match the route if the proc returns false" do
        @request.host = "unrecognised.example.com".sub(/^\./, '')
        lambda { recognize_path(@request) }.should raise_error(ActionController::RoutingError)
      end
    end
  end
end
