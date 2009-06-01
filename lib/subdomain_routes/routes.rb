module SubdomainRoutes
  module Routing
    module RouteSet
      include SplitHost
      
      def self.included(base)
        [ :extract_request_environment, :add_route ].each { |method| base.alias_method_chain method, :subdomains }
      end
      
      def extract_request_environment_with_subdomains(request)
        extract_request_environment_without_subdomains(request).merge(:subdomain => subdomain_for_host(request.host))
      end
      
      def add_route_with_subdomains(*args)
        options = args.extract_options!
        if subdomains = options.delete(:subdomains)
          options[:conditions] ||= {}
          options[:requirements] ||= {}
          case subdomains
          when Array
            options[:conditions][:subdomains] = subdomains
            options[:requirements][:subdomains] = subdomains
          when Hash
            options[:conditions][:subdomains] = subdomains[:resources]
            options[:requirements][:subdomains] = subdomains[:resources]
          end
        end
        with_options(options) { |routes| routes.add_route_without_subdomains(*args) }
      end
    end
  
    module Route
      def self.included(base)
        [ :recognition_conditions, :segment_keys, :recognition_extraction ].each { |method| base.alias_method_chain method, :subdomains }
      end
      
      def recognition_conditions_with_subdomains
        result = recognition_conditions_without_subdomains
        case conditions[:subdomains]
        when Array
          result << "conditions[:subdomains].include?(env[:subdomain])"
        when String
          result << "(subdomain = env[:subdomain] unless env[:subdomain].blank?)"
        end
        result
      end
      
      def segment_keys_with_subdomains
        result = segment_keys_without_subdomains
        result.unshift(:subdomain) if conditions[:subdomains].is_a? String #&& conditions[:subdomains][:resources]
        result
      end
      
      def recognition_extraction_with_subdomains
        result = recognition_extraction_without_subdomains
        if conditions[:subdomains].is_a? String
          result.unshift "params[:#{conditions[:subdomains].singularize.foreign_key}] = subdomain\n"
        end
        result
      end
    end
  end
end

ActionController::Routing::RouteSet.send :include, SubdomainRoutes::Routing::RouteSet
ActionController::Routing::Route.send :include, SubdomainRoutes::Routing::Route
