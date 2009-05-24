require 'spec_helper'

describe SubdomainRoutes do
  before(:each) do
    ActionController::Routing::Routes.clear!
    SubdomainRoutes::Config.stub!(:domain_length).and_return(2)
  end
  
  describe "resource mappings" do
    it "should pass the specified subdomains to any nested routes" do
      map_subdomain(:admin) do |admin|
        admin.resources(:users) { |user| user.options[:subdomains].should == [ :admin ] }
        admin.resource(:config) { |config| config.options[:subdomains].should == [ :admin ] }
      end
    end
  end
    
  describe "resource routes" do
    before(:each) do
      map_subdomain(:admin) do |admin|
        admin.resources :users
        admin.resource :config
      end
    end
      
    it "should include the subdomains in the routing conditions" do
      ActionController::Routing::Routes.routes.each do |route|
        route.conditions[:subdomains].should == [ :admin ]
      end
    end
    
    it "should include the subdomains in the routing conditions" do
      ActionController::Routing::Routes.routes.each do |route|
        route.requirements[:subdomains].should == [ :admin ]
      end
    end
  end
end
