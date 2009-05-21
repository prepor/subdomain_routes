require 'spec_helper'

def map_subdomain(*subdomains, &block)
  ActiveSupport::OptionMerger.send(:define_method, :options) { @options }
  ActiveSupport::OptionMerger.send(:define_method, :context) { @context }
  ActionController::Routing::Routes.draw do |map|
    map.subdomain(*subdomains, &block)
  end
end

describe SubdomainRoutes::UrlWriter do
  before(:each) do
    @request = ActionController::Request.new("HTTP_HOST" => "www.example.com")
    ActionController::Routing::Routes.clear!
  end
  
  it "should specify the the host if subdomain is different" do
    map_subdomain(:admin) do |admin|
      admin.foo "foo", :controller => "foo", :action => "bar"
    end
    admin_foo_path.should == "http://admin.example.com/foo"
  end
  
  it "should not specify the host if subdomain is the same" do
    map_subdomain(:www) do |www|
      www.foo "foo", :controller => "foo", :action => "bar"
    end
    www_foo_path.should == "/foo"
  end
  
  it "should not interfere with normal resource routes" do
    ActionController::Routing::Routes.draw do |map|
      map.resources :items
    end
    items_path.should == "/items"
    new_item_path.should == "/items/new"
    item_path(1).should == "/items/1"
    edit_item_path(1).should == "/items/1/edit"
  end
  
  it "should work with resources" do
    map_subdomain(:admin) do |admin|
      admin.resources :items
    end
    admin_items_path.should == "http://admin.example.com/items"
    new_admin_item_path.should == "http://admin.example.com/items/new"
    admin_item_path(1).should == "http://admin.example.com/items/1"
    edit_admin_item_path(1).should == "http://admin.example.com/items/1/edit"
  end
  
  it "should work with nested resources" do
    map_subdomain(:admin) do |admin|
      admin.resources :items do |item|
        item.resources :comments
      end
    end
    admin_item_comments_path(1).should == "http://admin.example.com/items/1/comments"
    new_admin_item_comment_path(1).should == "http://admin.example.com/items/1/comments/new"
    admin_item_comment_path(1, 2).should == "http://admin.example.com/items/1/comments/2"
    edit_admin_item_comment_path(1, 2).should == "http://admin.example.com/items/1/comments/2/edit"
  end  
end
