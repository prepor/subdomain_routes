require 'spec_helper'

def map_subdomain(*subdomains, &block)
  ActiveSupport::OptionMerger.send(:define_method, :options) { @options }
  ActionController::Routing::Routes.draw do |map|
    map.subdomain(*subdomains, &block)
  end
end

describe SubdomainRoutes do
  before(:each) do
    @request = ActionController::Request.new("HTTP_HOST" => "www.example.com", "METHOD" => "get")
    ActionController::Routing::Routes.clear!
  end
  
  describe "Routing" do
    it "should include a single specified subdomain in the options" do
      map_subdomain(:admin) do |admin|
        admin.options[:subdomains].should == [ :admin ]
      end
    end

    it "should include many specified subdomains in the options" do
      map_subdomain(:admin, :support) do |map|
        map.options[:subdomains].should == [ :admin, :support ]
      end
    end
  
    it "should raise ArgumentError if no subdomain is specified" do
      lambda { map_subdomain }.should raise_error(ArgumentError)
    end
    
    [ [ :admin ], [ :support, :admin ] ].each do |subdomains|
      context "mapping #{subdomains.size} subdomains" do
        it "should set the first subdomain as a namespace" do
          map_subdomain(*subdomains) do |map|
            map.options[:namespace].should == "#{subdomains.first}/"
          end
        end

        it "should prefix the first subdomain to named routes" do
          map_subdomain(*subdomains) do |map|
            map.options[:name_prefix].should == "#{subdomains.first}_"
          end
        end
        
        it "should instead set a namespace to the name if specified" do
          args = subdomains << { :name => :something }
          map_subdomain(*args) do |map|
            map.options[:namespace].should == "something/"
          end
        end

        it "should instead prefix the name to named routes if specified" do
          args = subdomains << { :name => :something }
          map_subdomain(*args) do |map|
            map.options[:name_prefix].should == "something_"
          end
        end

        it "should not set a namespace if name is specified as nil" do
          args = subdomains << { :name => nil }
          map_subdomain(*args) do |map|
            map.options[:namespace].should be_nil
          end
        end

        it "should not set a named route prefix if name is specified as nil" do
          args = subdomains << { :name => nil }
          map_subdomain(*args) do |map|
            map.options[:name_prefix].should be_nil
          end
        end
      end
    end
  end
    
  describe "Recognition" do
    it "should add the host's subdomain to the request environment" do
      @request.stub!(:request_method).and_return("GET")
      request_environment = ActionController::Routing::Routes.extract_request_environment(@request)
      request_environment[:subdomain].should == @request.host.downcase.split(".").first
      request_environment[:subdomain].should == "www"
    end
    
    context "for a single specified subdomain" do
      before(:each) do
        map_subdomain(:admin) do |map|
          map.resources :articles, :has_many => :comments
          map.foobar "foobar", :controller => "foo", :action => "bar"
          map.named_route "foobaz", "foobaz", :controller => "foo", :action => "baz"
          map.connect "/:controller/:action/:id"
        end
      end

      it "should add the specified subdomain to the route recognition conditions" do
        ActionController::Routing::Routes.routes.each do |route|
          route.conditions[:subdomains].should == [ :admin ]
        end
      end

      it "should add the subdomain to the route generation requirements" do
        ActionController::Routing::Routes.routes.each do |route|
          route.requirements[:subdomain].should == :admin
        end
      end
    end

    context "for multiple specified subdomains" do
      before(:each) do
        map_subdomain(:support, :admin) do |map|
          map.resources :articles, :has_many => :comments
          map.foobar "foobar", :controller => "foo", :action => "bar"
          map.named_route "foobaz", "foobaz", :controller => "foo", :action => "baz"
          map.connect "/:controller/:action/:id"
        end
      end

      it "should add the specified subdomain to the route recognition conditions" do
        ActionController::Routing::Routes.routes.each do |route|
          route.conditions[:subdomains].should == [ :support, :admin ]
        end
      end

      it "should not add a subdomain to the route generation requirements" do
        ActionController::Routing::Routes.routes.each do |route|
          route.requirements[:subdomain].should be_nil
        end
      end
    end
    
  end
  
  describe "UrlWriter" do
    context "when a single subdomain is specified in the route" do
      it "should force the host for a path if the request subdomain differs" do
        map_subdomain(:admin) { |admin| admin.resource :users }
        admin_users_path.should == "http://admin.example.com/users"
      end
      
      it "should not force the host for a path if the request subdomain is the same" do
        map_subdomain(:www) { |www| www.resource :users }
        www_users_path.should == "/users"
      end
    end

    context "when multiple subdomains are specified in the route" do
      it "should not force the host for a path if the request subdomain differs" do
        map_subdomain(:support, :admin, :name => nil) { |map| map.resource :users }
        users_path.should == "/users" # i.e. with the host being www.example.com, this route won't be recognised!
        # 
        # TODO:
        # 
        # This is a currently a limitation of the library.
        # 
        # Ideally, in this case the host should not be changed. Instead
        # an error should be raised if the request subdomain is not one
        # of the subdomains specified in the route, or a path generated
        # otherwise. Can't figure out how to do this!!
        # 
      end
    end
  end

  # it "should not interfere with normal resource routes" do
  #   ActionController::Routing::Routes.draw do |map|
  #     map.resources :items
  #   end
  #   items_path.should == "/items"
  #   new_item_path.should == "/items/new"
  #   item_path(1).should == "/items/1"
  #   edit_item_path(1).should == "/items/1/edit"
  # end
  # 
  # it "should work with resources" do
  #   map_subdomain(:admin) do |admin|
  #     admin.resources :items
  #   end
  #   admin_items_path.should == "http://admin.example.com/items"
  #   new_admin_item_path.should == "http://admin.example.com/items/new"
  #   admin_item_path(1).should == "http://admin.example.com/items/1"
  #   edit_admin_item_path(1).should == "http://admin.example.com/items/1/edit"
  # end
  # 
  # it "should work with nested resources" do
  #   map_subdomain(:admin) do |admin|
  #     admin.resources :items do |item|
  #       item.resources :comments
  #     end
  #   end
  #   admin_item_comments_path(1).should == "http://admin.example.com/items/1/comments"
  #   new_admin_item_comment_path(1).should == "http://admin.example.com/items/1/comments/new"
  #   admin_item_comment_path(1, 2).should == "http://admin.example.com/items/1/comments/2"
  #   edit_admin_item_comment_path(1, 2).should == "http://admin.example.com/items/1/comments/2/edit"
  # end  
end
