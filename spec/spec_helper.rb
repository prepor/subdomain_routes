require 'spec'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'subdomain_routes'

Spec::Runner.configure do |config|
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

def in_controller(&block)
  Class.new(ActionView::TestCase::TestController) do
    include Spec::Matchers
  end.new.instance_eval(&block)
end

def in_object(&block)
  Class.new do
    include Spec::Matchers
    include ActionController::UrlWriter
  end.new.instance_eval(&block)
end

def with_host(host, &block)
  variables = instance_variables.inject([]) do |array, name|
    array << [ name, instance_variable_get(name) ]
  end
  
  in_controller do
    request.host = host
    variables.each { |name, value| instance_variable_set(name, value) }
    instance_eval(&block)
  end
  
  in_object do
    self.class.default_url_options = { :host => host }
    variables.each { |name, value| instance_variable_set(name, value) }
    instance_eval(&block)
  end
end

def new_class(*names)
  names.map do |name|
    class_name = name.to_s.capitalize
    unless Object.const_defined?(class_name)
      klass = Class.new do
        attr_reader :id
        def save; @id = object_id; end
        def to_param; id.to_s; end
        def self.create; object = new; object.save; object; end
      end
      Object.const_set(class_name, klass)
    end
  end
end

new_class :item, :user
