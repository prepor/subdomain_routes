module SubdomainRoutes
  module Routing
    module RouteSet
      def self.included(base)
        base.alias_method_chain :extract_request_environment, :subdomain
        base.alias_method_chain :add_route, :subdomains
      end
      
      def extract_request_environment_with_subdomain(request)
        extract_request_environment_without_subdomain(request).merge(:subdomain => request.host.downcase.split(".").first)
      end
    
      def add_route_with_subdomains(*args)
        options = args.extract_options!
        if subdomains = options.delete(:subdomains)
          options[:conditions] ||= {}
          options[:conditions][:subdomains] = subdomains
        end
        args << options
        add_route_without_subdomains(*args)
      end

      module Mapper
        def subdomain(*subdomains, &block)
          options = subdomains.extract_options!
          raise ArgumentError.new("Please specify at least one subdomain!") if subdomains.empty?
          name = options.has_key?(:name) ? options.delete(:name) : subdomains.first
          subdomain_options = { :subdomains => subdomains, :conditions => { :subdomains => subdomains } }
          subdomain_options.merge! :name_prefix => "#{name}_", :namespace => "#{name}/" if name
          subdomain_options.merge! :requirements => { :subdomain => subdomains.first } if subdomains.size == 1
          # TODO fix this if you want subdomain limiting for multiple subdomains... (Also change in resources)
          # Maybe extract the requirements hash into a method?
          with_options(subdomain_options.merge(options), &block)
        end
      end
    end
  
    module Route
      def self.included(base)
        base.alias_method_chain :recognition_conditions, :subdomains
      end
      
      def recognition_conditions_with_subdomains
        result = recognition_conditions_without_subdomains
        # result << "[conditions[:subdomains]].flatten.map(&:to_s).include?(env[:subdomain])" if conditions[:subdomains]
        result << "conditions[:subdomains].map(&:to_s).include?(env[:subdomain])" if conditions[:subdomains]
        result
      end
    end
  end
end

ActionController::Routing::RouteSet.send :include, SubdomainRoutes::Routing::RouteSet
ActionController::Routing::RouteSet::Mapper.send :include, SubdomainRoutes::Routing::RouteSet::Mapper
ActionController::Routing::Route.send :include, SubdomainRoutes::Routing::Route
