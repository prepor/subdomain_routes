require 'spec_helper'

new_class :item, :user

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
    
    it "should be invoked by map.subdomains as well as map.subdomain" do
      ActionController::Routing::Routes.draw do |map|
        map.subdomains(:admin, :support) { |sub| sub.options[:subdomains].should == [ :admin, :support ] }
      end
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
          route.requirements[:subdomains].should == [ :admin ]
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
          route.requirements[:subdomains].should == [ :support, :admin ]
        end
      end
    end
  end
  
  describe "resources route" do
    it "should pass the specified subdomains to any nested routes" do
      map_subdomain(:admin) do |admin|
        admin.resources(:items) { |item| item.options[:subdomains].should == [ :admin ] }
        admin.resource(:config) { |config| config.options[:subdomains].should == [ :admin ] }
      end
    end
  end
    
  describe "route recognition" do
    before(:each) do
      @request = ActionController::TestRequest.new
      @request.host, @request.request_uri = "www.example.com", "/items/2"
      @subdomain = @request.host.downcase.split(".").first
    end
  
    it "should add the host's subdomain to the request environment" do
      request_environment = ActionController::Routing::Routes.extract_request_environment(@request)
      request_environment[:subdomain].should == @subdomain
    end
    
    context "for a single specified subdomain" do
      it "should recognise a route if the subdomain matches" do
        map_subdomain(@subdomain) { |subdomain| subdomain.resources :items }
        params = recognize_path(@request)
        params[:controller].should == "#{@subdomain}/items"
        params[:action].should == "show"
        params[:id].should == "2"
      end
    
      it "should not recognise a route if the subdomain doesn't match" do
        "admin".should_not == @subdomain
        map_subdomain("admin") { |admin| admin.resources :items }
        lambda { recognize_path(@request) }.should raise_error(ActionController::RoutingError)
      end
    end
    
    context "for multiple specified subdomains" do
      it "should recognise a route if the subdomain matches" do
        "admin".should_not == @subdomain
        map_subdomain(@subdomain, "admin", :name => nil) { |map| map.resources :items }
        params = recognize_path(@request)
        params[:controller].should == "items"
        params[:action].should == "show"
        params[:id].should == "2"
      end
    
      it "should not recognise a route if the subdomain doesn't match" do
        [ "support", "admin" ].each { |subdomain| subdomain.should_not == @subdomain }
        map_subdomain("support", "admin", :name => nil) { |map| map.resources :items }
        lambda { recognize_path(@request) }.should raise_error(ActionController::RoutingError)
      end
    end
  end
  
  describe "URL writing" do
    context "when included as a module and a host is not specified" do
      include ActionController::UrlWriter
  
      it "should raise an error when a subdomain route is requested" do
        map_subdomain(:www) { |www| www.resources :users }
        lambda { www_users_path }.should raise_error(SubdomainRoutes::HostNotSupplied)
      end
      
      context "and a non-subdomain route is requested" do
        before(:each) do
          ActionController::Routing::Routes.draw { |map| map.resources :users }
        end
  
        it "should not raise an error when a path is requested" do
          lambda { users_path }.should_not raise_error
        end
        
        it "should raise an error when an URL is requested" do
          lambda { users_url }.should raise_error
        end
      end
    end
    
    context "in a controller" do
      before(:each) do
        map_subdomain(:admin) { |admin| admin.resources :users }
      end
      
      it "should raise an error if the host is nil" do
        in_controller do
          request.host = nil
          lambda { admin_users_url }.should raise_error(SubdomainRoutes::SubdomainNotAvailable)
        end
      end
      
      it "should raise an error if the host is an ip address" do
        in_controller do
          request.host = "207.192.69.152"
          lambda { admin_users_url }.should raise_error(SubdomainRoutes::SubdomainNotAvailable)
        end
      end
    end
    
    context "when a single subdomain is specified in the route" do
      before(:each) do
        map_subdomain(:admin, :name => nil) { |admin| admin.resources :users }
        @user = User.create
      end
    
      it "should not change the host for an URL if the host subdomain matches" do
        with_host "admin.example.com" do
                 user_url(@user).should == "http://admin.example.com/users/#{@user.to_param}"
          polymorphic_url(@user).should == "http://admin.example.com/users/#{@user.to_param}"
        end
      end
      
      it "should change the host for an URL if the host subdomain differs" do
        with_host "www.example.com" do
                 user_url(@user).should == "http://admin.example.com/users/#{@user.to_param}"
          polymorphic_url(@user).should == "http://admin.example.com/users/#{@user.to_param}"
        end
      end
      
      it "should not force the host for a path if the host subdomain matches" do
        with_host "admin.example.com" do
                 user_path(@user).should == "/users/#{@user.to_param}"
          polymorphic_path(@user).should == "/users/#{@user.to_param}"
        end
      end
      
      it "should force the host for a path if the host subdomain differs" do
        with_host "www.example.com" do
                 user_path(@user).should == "http://admin.example.com/users/#{@user.to_param}"
          polymorphic_path(@user).should == "http://admin.example.com/users/#{@user.to_param}"
        end
      end
    
      context "and a subdomain different from the host subdomain is explicitly requested" do
        it "should change the host if the requested subdomain matches" do
          with_host "www.example.com" do
                   user_path(@user, :subdomain => :admin).should == "http://admin.example.com/users/#{@user.to_param}"
            polymorphic_path(@user, :subdomain => :admin).should == "http://admin.example.com/users/#{@user.to_param}"
          end
        end
      
        it "should raise an error if the requested subdomain doesn't match" do
          with_host "admin.example.com" do
            lambda {        user_path(@user, :subdomain => :www) }.should raise_error(ActionController::RoutingError)
            lambda { polymorphic_path(@user, :subdomain => :www) }.should raise_error(ActionController::RoutingError)
          end
        end
      end
    end
    
    context "when multiple subdomains are specified in the route" do
      before(:each) do
        map_subdomain(:books, :dvds, :name => nil) { |map| map.resources :items }
        @item = Item.create
      end
            
      it "should not change the host for an URL if the host subdomain matches" do
        [ "books.example.com", "dvds.example.com" ].each do |host|
          with_host(host) do
                   item_url(@item).should == "http://#{host}/items/#{@item.to_param}"
            polymorphic_url(@item).should == "http://#{host}/items/#{@item.to_param}"
          end
        end
      end
    
      it "should not force the host for a path if the host subdomain matches" do
        [ "books.example.com", "dvds.example.com" ].each do |host|
          with_host(host) do
                   item_path(@item).should == "/items/#{@item.to_param}"
            polymorphic_path(@item).should == "/items/#{@item.to_param}"
          end
        end
      end
    
      it "should raise an error if the host subdomain doesn't match" do
        with_host "www.example.com" do
          lambda {         item_url(@item) }.should raise_error(ActionController::RoutingError)
          lambda {        item_path(@item) }.should raise_error(ActionController::RoutingError)
          lambda {  polymorphic_url(@item) }.should raise_error(ActionController::RoutingError)
          lambda { polymorphic_path(@item) }.should raise_error(ActionController::RoutingError)
        end
      end
      
      context "and a subdomain different from the host subdomain is explicitly requested" do
        it "should change the host if the requested subdomain matches" do
          with_host "books.example.com" do
                   item_path(@item, :subdomain => :dvds).should == "http://dvds.example.com/items/#{@item.to_param}"
            polymorphic_path(@item, :subdomain => :dvds).should == "http://dvds.example.com/items/#{@item.to_param}"
          end
        end
    
        it "should raise an error if the requested subdomain doesn't match" do
          with_host "books.example.com" do
            lambda {        item_path(@item, :subdomain => :www) }.should raise_error(ActionController::RoutingError)
            lambda { polymorphic_path(@item, :subdomain => :www) }.should raise_error(ActionController::RoutingError)
          end
        end
      end
    end
  end
  
  # describe "configuration" do
  #   it "should have a default tld length of 2" do
  #     SubdomainRoutes::Config.tld_length.should == 2
  #   end
  #   
  #   it "should have a tld length setter" do
  #     SubdomainRoutes::Config.tld_length = 3
  #     SubdomainRoutes::Config.tld_length.should == 3
  #   end
  # end
end
