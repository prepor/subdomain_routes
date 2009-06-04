require 'spec'
$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'rubygems'
require 'active_support'
require 'action_controller'
require 'active_record' # only required for testing optional features, not required by the gem
require 'action_mailer' # only required for testing optional features, not required by the gem

require 'subdomain_routes'

Spec::Runner.configure do |config|
  config.before(:each) do
    ActionController::Routing::Routes.clear!
    SubdomainRoutes::Config.stub!(:domain_length).and_return(2)
  end
end

require 'action_controller/test_process'
require 'action_view/test_case'

ActiveSupport::OptionMerger.send(:define_method, :options) { @options }

def map_subdomain(*subdomains, &block)
  ActionController::Routing::Routes.draw do |map|
    map.subdomain(*subdomains, &block)
  end
end

def recognize_path(request)
  ActionController::Routing::Routes.recognize_path(request.path, ActionController::Routing::Routes.extract_request_environment(request))
end

def in_controller_with_host(host, &block)
  variables = instance_variables.inject([]) do |array, name|
    array << [ name, instance_variable_get(name) ]
  end
  Class.new(ActionView::TestCase::TestController) do
    include Spec::Matchers
  end.new.instance_eval do
    request.host = host
    variables.each { |name, value| instance_variable_set(name, value) }
    instance_eval(&block)
  end
end

def in_object_with_host(host, &block)
  variables = instance_variables.inject([]) do |array, name|
    array << [ name, instance_variable_get(name) ]
  end
  Class.new do
    include Spec::Matchers
    include ActionController::UrlWriter
  end.new.instance_eval do
    self.class.default_url_options = { :host => host }
    variables.each { |name, value| instance_variable_set(name, value) }
    instance_eval(&block)
  end
end

def with_host(host, &block)
  in_controller_with_host(host, &block)
  in_object_with_host(host, &block)
end

ActiveRecord::Base.class_eval do
  alias_method :save, :valid?
  def self.columns() @columns ||= []; end
  
  def self.column(name, sql_type = nil, default = nil, null = true)
    columns << ActiveRecord::ConnectionAdapters::Column.new(name.to_s, default, sql_type, null)
  end
end
