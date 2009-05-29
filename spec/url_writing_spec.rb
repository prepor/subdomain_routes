require 'spec_helper'

describe "URL writing" do
  before(:each) do
    ActionController::Routing::Routes.clear!
    SubdomainRoutes::Config.stub!(:domain_length).and_return(2)
  end
  
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

  [ [ "single", :admin, "admin.example.com" ],
    [    "nil",    nil,       "example.com" ] ].each do |type, subdomain, host|
    context "when a #{type} subdomain is specified" do
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
        with_host "other.example.com" do
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
        with_host "other.example.com" do
                 user_path(@user).should == "http://#{host}/users/#{@user.to_param}"
          polymorphic_path(@user).should == "http://#{host}/users/#{@user.to_param}"
        end
      end
  
      context "and a subdomain different from the host subdomain is explicitly requested" do
        it "should change the host if the requested subdomain matches" do
          with_host "other.example.com" do
                   user_path(@user, :subdomain => subdomain).should == "http://#{host}/users/#{@user.to_param}"
            polymorphic_path(@user, :subdomain => subdomain).should == "http://#{host}/users/#{@user.to_param}"
          end
        end
    
        it "should raise a routing error if the requested subdomain doesn't match" do
          with_host(host) do
            lambda {        user_path(@user, :subdomain => :other) }.should raise_error(ActionController::RoutingError)
            lambda { polymorphic_path(@user, :subdomain => :other) }.should raise_error(ActionController::RoutingError)
          end
        end
      end
      
      context "and the current host's subdomain is explicitly requested" do
        it "should not force the host for a path if the subdomain matches" do
          with_host(host) do
                   user_path(@user, :subdomain => subdomain).should == "/users/#{@user.to_param}"
            polymorphic_path(@user, :subdomain => subdomain).should == "/users/#{@user.to_param}"
          end
        end
      end
    end
  end
  
  [ [               "", [ :books, :dvds ], [ "books.example.com", "dvds.example.com" ] ],
    [ " including nil",     [ nil, :www ], [       "example.com",  "www.example.com" ] ] ].each do |qualifier, subdomains, hosts|
    context "when multiple subdomains#{qualifier} are specified" do
      before(:each) do
        args = subdomains + [ :name => nil ]
        map_subdomain(*args) { |map| map.resources :items }
        @item = Item.create
      end
          
      it "should not change the host for an URL if the host subdomain matches" do
        hosts.each do |host|
          with_host(host) do
                   item_url(@item).should == "http://#{host}/items/#{@item.to_param}"
            polymorphic_url(@item).should == "http://#{host}/items/#{@item.to_param}"
          end
        end
      end
  
      it "should not force the host for a path if the host subdomain matches" do
        hosts.each do |host|
          with_host(host) do
                   item_path(@item).should == "/items/#{@item.to_param}"
            polymorphic_path(@item).should == "/items/#{@item.to_param}"
          end
        end
      end
  
      it "should raise a routing error if the host subdomain doesn't match" do
        with_host "other.example.com" do
          lambda {         item_url(@item) }.should raise_error(ActionController::RoutingError)
          lambda {        item_path(@item) }.should raise_error(ActionController::RoutingError)
          lambda {  polymorphic_url(@item) }.should raise_error(ActionController::RoutingError)
          lambda { polymorphic_path(@item) }.should raise_error(ActionController::RoutingError)
        end
      end
    
      context "and a subdomain different from the host subdomain is explicitly requested" do
        it "should change the host if the requested subdomain matches" do
          [ [ subdomains.first, hosts.first, hosts.last ],
            [ subdomains.last, hosts.last, hosts.first ] ].each do |subdomain, new_host, old_host|
            with_host(old_host) do
                     item_path(@item, :subdomain => subdomain).should == "http://#{new_host}/items/#{@item.to_param}"
              polymorphic_path(@item, :subdomain => subdomain).should == "http://#{new_host}/items/#{@item.to_param}"
            end
          end
        end
          
        it "should raise a routing error if the requested subdomain doesn't match" do
          [ [ hosts.first, hosts.last ],
            [ hosts.last, hosts.first ] ].each do |new_host, old_host|
            with_host(old_host) do
              lambda {        item_path(@item, :subdomain => :other) }.should raise_error(ActionController::RoutingError)
              lambda { polymorphic_path(@item, :subdomain => :other) }.should raise_error(ActionController::RoutingError)
            end
          end
        end
      end
    end
  end
  
  it "should downcase a supplied subdomain" do
    map_subdomain(:www1, :www2, :name => nil) { |map| map.resources :users }
    [ [ :Www1, "www1" ], [ "Www2", "www2" ] ].each do |mixedcase, lowercase|
      with_host "www.example.com" do
        users_url(:subdomain => mixedcase).should == "http://#{lowercase}.example.com/users"
      end
    end
  end
  
  context "when a :proc subdomain is specified" do          
    before(:each) do
      map_subdomain(:proc => :city) { |city| city.resources :events }
    end
    
    it "should raise a routing error without a verify proc" do
      with_host "boston.example.com" do
        lambda {  city_events_url }.should raise_error(ActionController::RoutingError)
        lambda { city_events_path }.should raise_error(ActionController::RoutingError)
      end
    end
    
    context "and a verify proc is defined" do
      before(:each) do
        ActionController::Routing::Routes.verify_subdomain(:city) { |city| } # this block will be stubbed
      end
      
      it "should not change the host if the verify proc returns true" do
        with_host "boston.example.com" do
          ActionController::Routing::Routes.subdomain_procs.should_receive(:verify).twice.with(:city, "boston").and_return(true)
          city_events_url.should == "http://boston.example.com/events"
          city_events_path.should == "/events"
        end
      end
    
      it "should raise a routing error if the verify proc returns false" do
        with_host "www.example.com" do
          ActionController::Routing::Routes.subdomain_procs.should_receive(:verify).twice.with(:city, "www").and_return(false)
          lambda { city_events_url  }.should raise_error(ActionController::RoutingError)
          lambda { city_events_path }.should raise_error(ActionController::RoutingError)
        end
      end
    
      it "should force the host if the verify proc returns false but a matching subdomain is supplied" do
        with_host "www.example.com" do
          ActionController::Routing::Routes.subdomain_procs.should_receive(:verify).twice.with(:city, "boston").and_return(true)
           city_events_url(:subdomain => :boston).should == "http://boston.example.com/events"
          city_events_path(:subdomain => :boston).should == "http://boston.example.com/events"
        end
      end
    
      it "should raise a routing error if the verify proc returns false and a non-matching subdomain is supplied" do
        with_host "www.example.com" do
          ActionController::Routing::Routes.subdomain_procs.should_receive(:verify).twice.with(:city, "hobart").and_return(false)
          lambda {  city_events_url(:subdomain => :hobart) }.should raise_error(ActionController::RoutingError)
          lambda { city_events_path(:subdomain => :hobart) }.should raise_error(ActionController::RoutingError)
        end
      end
    
      context "and a generate proc is also defined" do
        before(:each) do
          ActionController::Routing::Routes.generate_subdomain(:city) { |request, context| } # this block will be stubbed
          ActionController::Routing::Routes.subdomain_procs.stub!(:verify).with(:city, "canberra").and_return(true)
        end
        
        it "should downcase the output of the generate proc" do
          [ :Canberra, "Canberra" ].each do |mixedcase|
            with_host "www.example.com" do
              ActionController::Routing::Routes.subdomain_procs.should_receive(:generate).and_return(mixedcase)
              city_events_path.should == "http://canberra.example.com/events"
            end
          end
        end
    
        it "should generate the URL in a controller using the session" do
          in_controller_with_host "www.example.com" do
            ActionController::Routing::Routes.subdomain_procs.should_receive(:generate).with(:city, request, nil).and_return("canberra")
            city_events_path.should == "http://canberra.example.com/events"
          end
        end
    
        it "should generate the URL in an object using a supplied context" do
          in_object_with_host "www.example.com" do
            ActionController::Routing::Routes.subdomain_procs.should_receive(:generate).with(:city, nil, :city_id => 2 ).and_return("canberra")
            city_events_path(:context => { :city_id => 2 }).should == "http://canberra.example.com/events"
          end
        end
    
        it "should raise any error that the generate proc raises" do
          with_host "www.example.com" do
            error = StandardError.new
            ActionController::Routing::Routes.subdomain_procs.should_receive(:generate).and_raise(error)
            lambda { city_events_path }.should raise_error { |e| e.should == error }
          end
        end
        
        it "should run the verifier on the generated subdomain and raise a routing error if the subdomain is invalid" do
          ActionController::Routing::Routes.subdomain_procs.stub!(:generate).and_return("www")
          with_host "www.example.com" do
            ActionController::Routing::Routes.subdomain_procs.should_receive(:verify).with(:city, "www").and_return(false)
            lambda { city_events_path }.should raise_error(ActionController::RoutingError)
          end
        end

        it "should run the verifier on the generated subdomain and produce the URL if the subdomain is valid" do
          ActionController::Routing::Routes.subdomain_procs.stub!(:generate).and_return("hobart")
          with_host "www.example.com" do
            ActionController::Routing::Routes.subdomain_procs.should_receive(:verify).with(:city, "hobart").and_return(true)
            lambda { city_events_path }.should_not raise_error
          end
        end
        
        it "should raise a routing error if the generated subdomain has an illegal format" do
          ActionController::Routing::Routes.subdomain_procs.stub!(:verify).and_return(true)
          [ :ww_w, "ww_w", "w w w", "www!", "123" ].each do |subdomain|
            with_host "www.example.com" do
              ActionController::Routing::Routes.subdomain_procs.should_receive(:generate).and_return(subdomain)
              lambda { city_events_path }.should raise_error(ActionController::RoutingError)
            end
          end
        end
      end
    end
  end
end

describe "URL rewriter" do
  it "should flush the subdomain procs cache on initialization" do
    ActionController::Routing::Routes.subdomain_procs.should_receive(:flush!)
    in_controller_with_host("mholling.example.com") { }
  end
  
  it "should not flush the subdomain procs cache on initialization if Config::manual_flush is set" do
    SubdomainRoutes::Config.stub!(:manual_flush).and_return(true)
    ActionController::Routing::Routes.subdomain_procs.should_not_receive(:flush!)
    in_controller_with_host("mholling.example.com") { }
  end
end