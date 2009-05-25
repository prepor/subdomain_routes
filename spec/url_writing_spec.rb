require 'spec_helper'

describe SubdomainRoutes do
  before(:each) do
    ActionController::Routing::Routes.clear!
    SubdomainRoutes::Config.stub!(:domain_length).and_return(2)
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

    # 
    # it "should work with" do
    #   map_subdomain(:www) { |www| www.resources :items }
    #   with_host "www.example.com" do
    #     www_items_path(:subdomain => "www").should == "/items"
    #     www_items_path(:subdomain => :www).should == "/items"
    #   end
    # end

    [ [ "single", :admin, "admin.example.com" ],
      [    "nil",    nil,       "example.com" ] ].each do |type, subdomain, host|
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
      
          it "should raise an error if the requested subdomain doesn't match" do
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
      context "when multiple subdomains#{qualifier} are specified in the route" do
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
    
        it "should raise an error if the host subdomain doesn't match" do
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
            
          it "should raise an error if the requested subdomain doesn't match" do
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
  end  
end
