require 'spec_helper'

def map_subdomain(*subdomains, &block)
  ActiveSupport::OptionMerger.send(:define_method, :options) { @options }
  ActionController::Routing::Routes.draw do |map|
    map.subdomain(*subdomains, &block)
  end
end

def environment(headers = {})
  { 'REQUEST_METHOD' => "GET",
    'QUERY_STRING'   => "",
    "REQUEST_URI"    => "/",
    "HTTP_HOST"      => "www.example.com",
    "SERVER_PORT"    => "80",
    "HTTPS"          => "off" }.merge(headers)
end

def recognize_path(request)
  ActionController::Routing::Routes.recognize_path(request.path, ActionController::Routing::Routes.extract_request_environment(request))
end


describe SubdomainRoutes do
  before(:each) do
    ActionController::Routing::Routes.clear!
  end
  
  describe "route" do
    it "should include a single specified subdomain in the options" do
      map_subdomain(:admin) { |admin| admin.options[:subdomains].should == [ :admin ] }
    end

    it "should include many specified subdomains in the options" do
      map_subdomain(:admin, :support) { |map| map.options[:subdomains].should == [ :admin, :support ] }
    end
  
    it "should raise ArgumentError if no subdomain is specified" do
      lambda { map_subdomain }.should raise_error(ArgumentError)
    end
    
    [ [ :admin ], [ :support, :admin ] ].each do |subdomains|
      context "mapping #{subdomains.size} subdomains" do
        it "should set the first subdomain as a namespace" do
          map_subdomain(*subdomains) { |map| map.options[:namespace].should == "#{subdomains.first}/" }
        end

        it "should prefix the first subdomain to named routes" do
          map_subdomain(*subdomains) { |map| map.options[:name_prefix].should == "#{subdomains.first}_" }
        end
        
        it "should instead set a namespace to the name if specified" do
          args = subdomains << { :name => :something }
          map_subdomain(*args) { |map| map.options[:namespace].should == "something/" }
        end

        it "should instead prefix the name to named routes if specified" do
          args = subdomains << { :name => :something }
          map_subdomain(*args) { |map| map.options[:name_prefix].should == "something_" }
        end

        it "should not set a namespace if name is specified as nil" do
          args = subdomains << { :name => nil }
          map_subdomain(*args) { |map| map.options[:namespace].should be_nil }
        end

        it "should not set a named route prefix if name is specified as nil" do
          args = subdomains << { :name => nil }
          map_subdomain(*args) { |map| map.options[:name_prefix].should be_nil }
        end
      end
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
  
  describe "resources route" do
    it "should transfer specified subdomains to any nested routes" do
      map_subdomain(:admin) do |admin|
        admin.resources(:items) { |item| item.options[:subdomains].should == [ :admin ] }
        admin.resource(:config) { |config| config.options[:subdomains].should == [ :admin ] }
      end
    end
  end
    
  describe "route recognition" do
    before(:each) do
      @environment = environment("HTTP_HOST" => "www.example.com", "REQUEST_URI" => "/items/2")
      @request = ActionController::Request.new(@environment)
      class ItemsController < ActionController::Base; end
    end

    it "should add the host's subdomain to the request environment" do
      request_environment = ActionController::Routing::Routes.extract_request_environment(@request)
      request_environment[:subdomain].should == @request.host.downcase.split(".").first
      request_environment[:subdomain].should == "www"
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
        map_subdomain(:admin) { |admin| admin.resources :items }
        lambda { recognize_path(@request) }.should raise_error(ActionController::RoutingError)
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
  end
  
  # # TODO: url writing and rewriting is all we have left to test!
  
  # describe "UrlWriter" do
  #   include ActionController::UrlWriter
  #   
  #   context "when a single subdomain is specified in the route" do
  #     it "should force the host for a path if the host subdomain differs" do
  #       map_subdomain(:admin) { |admin| admin.resources :users }
  #       admin_users_path(:host => "www.example.com").should == "http://admin.example.com/users"
  #     end
  #     
  #     it "should not force the host for a path if the host subdomain is the same" do
  #       map_subdomain(:www) { |www| www.resources :users }
  #       www_users_path(:host => "www.example.com").should == "/users"
  #     end
  #   end
  # end
  
  # describe "UrlRewriter" do
  #   
  #   context "when multiple subdomains are specified in the route" do
  #     it "should not force the host for a path if the request subdomain differs" do
  #       map_subdomain(:www, :name => nil) { |map| map.resources :users }
  #       @rewriter.rewrite(:controller => :users, :action => :index).should == "/users" # i.e. with the host being www.example.com, this route won't be recognised!
  #       # 
  #       # TODO:
  #       # 
  #       # This is a currently a limitation of the library.
  #       # 
  #       # Ideally, in this case the host should not be changed. Instead
  #       # an error should be raised if the request subdomain is not one
  #       # of the subdomains specified in the route, or a path generated
  #       # otherwise. Can't figure out how to do this!!
  #       # 
  #     end
  #   end
  # end
end
