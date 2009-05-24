require 'spec_helper'

new_class :item, :user

describe SubdomainRoutes do
  before(:each) do
    ActionController::Routing::Routes.clear!
  end
  
  describe "configuration" do
    it "should have a default domain length of 2" do
      # stub the domain_length instead?? these tests are dodgy...
      SubdomainRoutes::Config.domain_length.should == 2
    end
    
    it "should let the domain length be changed" do
      SubdomainRoutes::Config.domain_length = 3
      SubdomainRoutes::Config.domain_length.should == 3
      SubdomainRoutes::Config.domain_length = 2
    end
  end
  
  describe "subdomain extraction" do
    include SubdomainRoutes::SplitHost
    
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
  
  describe "subdomain routes" do
    it "should raise an error if the specified subdomains have illegal characters" do
      [ :ww_w, "w w w", "www!" ].each do |subdomain|
        lambda { map_subdomain(subdomain) { } }.should raise_error(ArgumentError)
      end
      [ "www1", "www-1", "123" ].each do |subdomain|
        lambda { map_subdomain(subdomain) { } }.should_not raise_error
      end
    end

    it "should include a nil subdomain in the options" do
      map_subdomain(nil) { |map| map.options[:subdomains].should == [ nil ] }
    end

    it "should include a single specified subdomain in the options" do
      map_subdomain(:admin) { |admin| admin.options[:subdomains].should == [ :admin ] }
    end
  
    it "should include many specified subdomains in the options" do
      map_subdomain(:admin, :support) { |map| map.options[:subdomains].should == [ :admin, :support ] }
    end
  
    it "should raise ArgumentError if no subdomain is specified" do
      lambda { map_subdomain }.should raise_error(ArgumentError)
    end
    
    it "should not include repeated subdomains in the options" do
      map_subdomain(:admin, :support, :admin) { |map| map.options[:subdomains].should == [ :admin, :support ] }
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
          args = subdomains + [ :name => :something ]
          map_subdomain(*args) { |map| map.options[:namespace].should == "something/" }
        end
  
        it "should instead prefix the name to named routes if specified" do
          args = subdomains + [ :name => :something ]
          map_subdomain(*args) { |map| map.options[:name_prefix].should == "something_" }
        end
  
        it "should not set a namespace if name is specified as nil" do
          args = subdomains + [ :name => nil ]
          map_subdomain(*args) { |map| map.options[:namespace].should be_nil }
        end
  
        it "should not set a named route prefix if name is specified as nil" do
          args = subdomains + [ :name => nil ]
          map_subdomain(*args) { |map| map.options[:name_prefix].should be_nil }
        end
      end
    end
    
    context "mapping the nil subdomain" do
      it "should not set a namespace" do
        map_subdomain(nil) { |map| map.options[:namespace].should be_nil }
      end

      it "should not set a named route prefix" do
        map_subdomain(nil) { |map| map.options[:name_prefix].should be_nil }
      end
    end
    
    context "mapping nil and other subdomains" do
      it "should set the first non-nil subdomain as a namespace" do
        map_subdomain(nil, :www) { |map| map.options[:namespace].should == "www/" }
      end

      it "should prefix the first non-nil subdomain to named routes" do
        map_subdomain(nil, :www) { |map| map.options[:name_prefix].should == "www_" }
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
  
  describe "resources routes" do
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
  end
  
  describe "URL writing" do
    { "nil" => nil, "an IP address" => "207.192.69.152" }.each do |host_type, host|
      context "when the host is #{host_type}" do
        it "should raise an error when a subdomain route is requested" do
          map_subdomain(:www) { |www| www.resources :users }
          with_host(host) { lambda { www_users_path }.should raise_error(SubdomainRoutes::HostNotSupplied) }
        end
        
        context "and a non-subdomain route is requested" do
          before(:each) do
            ActionController::Routing::Routes.draw { |map| map.resources :users }
          end

          it "should not raise an error when the route is a path" do
            with_host(host) do
              lambda { users_path }.should_not raise_error
            end
          end
        end
      end
    end
        
    [ [ "single", :admin, "admin.example.com" ], [ "nil", nil, "example.com" ] ].each do |type, subdomain, host|
      context "when a #{type} subdomain is specified in the route" do
        before(:each) do
          map_subdomain(subdomain, :name => nil) { |map| map.resources :users }
          @user = User.create
        end
    
        it "should not change the host for an URL if the host subdomain matches" do
          with_host(host) do
                   user_url(@user).should == "http://#{host}/users/#{@user.to_param}"
            polymorphic_url(@user).should == "http://#{host}/users/#{@user.to_param}"
          end
        end
      
        it "should change the host for an URL if the host subdomain differs" do
          with_host "www.example.com" do
                   user_url(@user).should == "http://#{host}/users/#{@user.to_param}"
            polymorphic_url(@user).should == "http://#{host}/users/#{@user.to_param}"
          end
        end
      
        it "should not force the host for a path if the host subdomain matches" do
          with_host(host) do
                   user_path(@user).should == "/users/#{@user.to_param}"
            polymorphic_path(@user).should == "/users/#{@user.to_param}"
          end
        end
      
        it "should force the host for a path if the host subdomain differs" do
          with_host "www.example.com" do
                   user_path(@user).should == "http://#{host}/users/#{@user.to_param}"
            polymorphic_path(@user).should == "http://#{host}/users/#{@user.to_param}"
          end
        end
    
        context "and a subdomain different from the host subdomain is explicitly requested" do
          it "should change the host if the requested subdomain matches" do
            with_host "www.example.com" do
                     user_path(@user, :subdomain => subdomain).should == "http://#{host}/users/#{@user.to_param}"
              polymorphic_path(@user, :subdomain => subdomain).should == "http://#{host}/users/#{@user.to_param}"
            end
          end
      
          it "should raise an error if the requested subdomain doesn't match" do
            with_host(host) do
              lambda {        user_path(@user, :subdomain => :www) }.should raise_error(ActionController::RoutingError)
              lambda { polymorphic_path(@user, :subdomain => :www) }.should raise_error(ActionController::RoutingError)
            end
          end
        end
      end
    end
    
    # TODO: add the [ nil, :www ] combination?
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
  
  # TODO: split this file into multiple spec files!
end
