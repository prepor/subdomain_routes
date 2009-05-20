require 'spec_helper'

def map_subdomain(*subdomains, &block)
  ActionController::Routing::Routes.draw do |map|
    ActiveSupport::OptionMerger.send(:define_method, :options) { @options }
    ActiveSupport::OptionMerger.send(:define_method, :context) { @context }
    map.subdomain(*subdomains, &block)
  end
end


describe SubdomainRoutes::UrlWriter do
  before(:each) do
    @request = ActionController::Request.new("HTTP_HOST" => "www.example.com")
    ActionController::Routing::Routes.clear!
  end

  it "blah" do
    map_subdomain(:admin) do |admin|
      admin.foo "foo", :controller => "foo", :action => "bar"
      puts admin_foo_path
      puts admin.options.inspect
      admin.resources :users do |user|
        puts user.options.inspect
        user.blah 'blah', :controller => "blah", :action => "show"
        user.resources :items do |item|
          puts item.options.inspect
        end
      end
    end
    admin_users_path.should == "http://admin.example.com/users"
    admin_user_blah_path(2).should == "http://admin.example.com/users/2/blah"
    class User
      def to_param; "2"; end
    end
    class Item
      def to_param; "10"; end
    end
    puts admin_user_item_path(User.new, Item.new)
  end
  
  it "named route" do
    map_subdomain(:admin) do |admin|
      admin.blah "blah", :controller => "blah", :action => "show"
    end
    admin_blah_path.should == "http://admin.example.com/blah"
  end
  
  [ [ :admin ], [ :blog, :admin ] ].each do |subdomains|
    context "mapping #{subdomains.size} subdomains" do
      first = subdomains.first
      map_subdomain(*subdomains) do |map|
        it "should prefix subdomain to named routes" do
          map.options[:name_prefix].should == "#{first}_"
        end
      
        it "should add the subdomain as a namespace" do
          map.options[:namespace].should == "#{first}/"
        end
      
        it "should specify subdomain in options" do
          map.options[:subdomains].should == subdomains
          map.options[:conditions][:subdomains].should == subdomains
        end
      end
    
      context "with a name specified" do
        args = subdomains + [{:name => :www}]
        map_subdomain(*args) do |map|
          it "should prefix the name to named routes" do
            map.options[:name_prefix].should == "www_"
          end
        
          it "should add the name as a namespace" do
            map.options[:namespace].should == "www/"
          end
        
          it "should specify subdomain in options" do
            map.options[:subdomains].should == subdomains
            map.options[:conditions][:subdomains].should == subdomains
          end
        end
      end

      context "with nil name specified" do
        args = subdomains + [{:name => nil}]
        map_subdomain(*args) do |map|
          it "should not add a prefix to named routes" do
            map.options[:name_prefix].should be_nil
          end
        
          it "should not add a namespace" do
            map.options[:namespace].should be_nil
          end
        
          it "should specify subdomain in options" do
            map.options[:subdomains].should == subdomains
            map.options[:conditions][:subdomains].should == subdomains
          end
        end
      end
      
      context "with name specified and namespace set to nil" do
        args = subdomains + [{:name => :www, :namespace => nil}]
        map_subdomain(*args) do |map|
          it "should prefix the name to named routes" do
            map.options[:name_prefix].should == "www_"
          end
        
          it "should not add a namespace" do
            map.options[:namespace].should be_nil
          end
        
          it "should specify subdomain in options" do
            map.options[:subdomains].should == subdomains
            map.options[:conditions][:subdomains].should == subdomains
          end
        end
      end
    end
  end
  
  
end
