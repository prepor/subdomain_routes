module SubdomainRoutes
  module Routing
    module RouteSet
      include SplitHost
      
      def self.included(base)
        [ :extract_request_environment, :add_route, :clear! ].each { |method| base.alias_method_chain method, :subdomains }
      end
      
      def extract_request_environment_with_subdomains(request)
        extract_request_environment_without_subdomains(request).merge(:subdomain => subdomain_for_host(request.host))
      end
    
      def add_route_with_subdomains(*args)
        options = args.extract_options!
        if subdomains = options.delete(:subdomains)
          options[:conditions] ||= {}
          options[:conditions][:subdomains] = subdomains
          options[:requirements] ||= {}
          options[:requirements][:subdomains] = subdomains
        end
        with_options(options) { |routes| routes.add_route_without_subdomains(*args) }
      end
      
      def verify_subdomain(name, &block)
        method = "#{name}_subdomain?"
        (class << self; self; end).send(:define_method, method, &block)
        @subdomain_procs ||= []
        @subdomain_procs << method
        # TODO: test this
      end

      def generate_subdomain(name, &block)
        method = "#{name}_subdomain"
        (class << self; self; end).send(:define_method, method, &block)
        @subdomain_procs ||= []
        @subdomain_procs << method
        # TODO: test this
      end
      
      def clear_with_subdomains!
        @subdomain_procs.each { |proc| self.class_eval { remove_method proc } } if @subdomain_procs
        remove_instance_variable("@subdomain_procs") if instance_variable_defined?("@subdomain_procs")
        clear_without_subdomains!
      end
    end
  
    module Route
      def self.included(base)
        base.alias_method_chain :recognition_conditions, :subdomains
      end
      
      def recognition_conditions_with_subdomains
        result = recognition_conditions_without_subdomains
        case conditions[:subdomains]
        when Array
          result << "conditions[:subdomains].include?(env[:subdomain])"
        when Hash
          if subdomain = conditions[:subdomains][:proc]
            method = "#{subdomain}_subdomain?"
            result << %Q{(ActionController::Routing::Routes.#{method}(env[:subdomain]) if ActionController::Routing::Routes.respond_to?(:#{method}))}
          end
        end
        result
      end
    end
  end
end

ActionController::Routing::RouteSet.send :include, SubdomainRoutes::Routing::RouteSet
ActionController::Routing::Route.send :include, SubdomainRoutes::Routing::Route
