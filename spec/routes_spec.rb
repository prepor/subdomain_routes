require 'spec_helper'

describe "subdomain routes" do
  before(:each) do
    ActionController::Routing::Routes.clear!
    SubdomainRoutes::Config.stub!(:domain_length).and_return(2)
  end
  
  it "should raise an error if the specified subdomains have illegal characters" do
    [ :ww_w, "ww_w", "w w w", "www!", "123" ].each do |subdomain|
      lambda { map_subdomain(subdomain) { } }.should raise_error(ArgumentError)
    end
  end
  
  it "should accept all legal subdomains" do
    [ "www1", "www-1" ].each do |subdomain|
      lambda { map_subdomain(subdomain) { } }.should_not raise_error
    end
  end

  it "should accept a nil subdomain" do
    map_subdomain(nil) { |map| map.options[:subdomains].should == [ "" ] }
  end

  it "should accept a blank subdomain" do
    map_subdomain("") { |map| map.options[:subdomains].should == [ "" ] }
  end

  it "should accept a single specified subdomain" do
    map_subdomain(:admin) { |admin| admin.options[:subdomains].should == [ "admin" ] }
  end
  
  it "should accept strings or symbols as subdomains" do
    map_subdomain(:admin)  { |admin| admin.options[:subdomains].should == [ "admin" ] }
    map_subdomain("admin") { |admin| admin.options[:subdomains].should == [ "admin" ] }
  end

  it "should accept many specified subdomains" do
    map_subdomain(:admin, :support) { |map| map.options[:subdomains].should == [ "admin", "support" ] }
  end
  
  it "should accept a :proc option as the subdomain" do
    map_subdomain(:proc => :name) { |name| name.options[:subdomains].should == { :proc => :name } }
  end

  it "should raise ArgumentError if no subdomain is specified" do
    lambda { map_subdomain }.should raise_error(ArgumentError)
  end
  
  it "should not include repeated subdomains in the options" do
    map_subdomain(:admin, :support, :admin) { |map| map.options[:subdomains].should == [ "admin", "support" ] }
  end
  
  it "should be invoked by map.subdomains as well as map.subdomain" do
    ActionController::Routing::Routes.draw do |map|
      map.subdomains(:admin, :support) { |sub| sub.options[:subdomains].should == [ "admin", "support" ] }
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
  
  it "should strip bad characters from the namespace and name prefix" do
    map_subdomain("just-do-it") { |map| map.options[:namespace].should == "just_do_it/" }
    map_subdomain("just-do-it") { |map| map.options[:name_prefix].should == "just_do_it_" }
    map_subdomain(nil, :name => "just-do-it") { |map| map.options[:namespace].should == "just_do_it/" }
    map_subdomain(nil, :name => "just-do-it") { |map| map.options[:name_prefix].should == "just_do_it_" }
    map_subdomain(nil, :name => "Just do it!") { |map| map.options[:namespace].should == "just_do_it/" }
    map_subdomain(nil, :name => "Just do it!") { |map| map.options[:name_prefix].should == "just_do_it_" }
  end
  
  context "mapping the nil subdomain" do
    it "should not set a namespace" do
      [ nil, "" ].each do |none|
        map_subdomain(none) { |map| map.options[:namespace].should be_nil }
      end
    end

    it "should not set a named route prefix" do
      [ nil, "" ].each do |none|
        map_subdomain(none) { |map| map.options[:name_prefix].should be_nil }
      end
    end
  end
  
  context "mapping nil and other subdomains" do
    it "should set the first non-nil subdomain as a namespace" do
      [ nil, "" ].each do |none|
        map_subdomain(none, :www) { |map| map.options[:namespace].should == "www/" }
      end
    end

    it "should prefix the first non-nil subdomain to named routes" do
      [ nil, "" ].each do |none|
        map_subdomain(none, :www) { |map| map.options[:name_prefix].should == "www_" }
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
        route.conditions[:subdomains].should == [ "admin" ]
      end
    end

    it "should add the subdomain to the route generation requirements" do
      ActionController::Routing::Routes.routes.each do |route|
        route.requirements[:subdomains].should == [ "admin" ]
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
        route.conditions[:subdomains].should == [ "support", "admin" ]
      end
    end

    it "should not add a subdomain to the route generation requirements" do
      ActionController::Routing::Routes.routes.each do |route|
        route.requirements[:subdomains].should == [ "support", "admin" ]
      end
    end
  end
      
  context "for a :proc subdomain" do
    it "should set the value a namespace" do
      map_subdomain(:proc => :city) { |city| city.options[:namespace].should == "city/" }
    end

    it "should prefix the value to named routes" do
      map_subdomain(:proc => :city) { |city| city.options[:name_prefix].should == "city_" }
    end
  
    it "should set a namespace to the name if specified" do
      map_subdomain(:proc => :city, :name => :something) { |city| city.options[:namespace].should == "something/" }
    end

    it "should prefix the name to named routes if specified" do
      map_subdomain(:proc => :city, :name => :something) { |city| city.options[:name_prefix].should == "something_" }
    end

    it "should add the specified proc to the route recognition conditions" do
      map_subdomain(:proc => :city) { |city| city.resources :events }
      ActionController::Routing::Routes.routes.each do |route|
        route.conditions[:subdomains].should == { :proc => :city }
      end
    end
      
    it "should add the specified proc to the route generation requirements" do
      map_subdomain(:proc => :city) { |city| city.resources :events }
      ActionController::Routing::Routes.routes.each do |route|
        route.requirements[:subdomains].should == { :proc => :city }
      end
    end
    
    it "should add a subdomain verification method to ActionController::Routing::Routes" do
      ActionController::Routing::Routes.should_not respond_to("city_subdomain?")
      ActionController::Routing::Routes.verify_subdomain(:city) { |city| city == "perth" }
      ActionController::Routing::Routes.should respond_to("city_subdomain?")
    end
    
    it "should add a subdomain generation method to ActionController::Routing::Routes" do
      ActionController::Routing::Routes.should_not respond_to("city_subdomain")
      ActionController::Routing::Routes.generate_subdomain(:city) { "perth" }
      ActionController::Routing::Routes.should respond_to("city_subdomain")
    end

    it "should clear subdomain verification and generation methods when ActionController::Routing::Routes are cleared" do
      ActionController::Routing::Routes.verify_subdomain(:city) { |city| city == "perth" }
      ActionController::Routing::Routes.generate_subdomain(:city) { "perth" }
      ActionController::Routing::Routes.clear!
      ActionController::Routing::Routes.should_not respond_to("city_subdomain?")
      ActionController::Routing::Routes.should_not respond_to("city_subdomain")
    end
  end
end
