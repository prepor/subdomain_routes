module SubdomainRoutes
  module Routing
    module RouteSet
      include SplitHost
      
      module Mapper
        def subdomain(*subdomains, &block)
          options = subdomains.extract_options!
          if subdomains.empty?
            if proc = options.delete(:proc)
              subdomain_options = { :subdomains => { :proc => proc } }
              name = options.delete(:name)
            else
              raise ArgumentError, "Please specify at least one subdomain!"
            end
          else
            subdomains.map! { |subdomain| subdomain.nil? ? subdomain : subdomain.to_s }
            subdomains.uniq!
            subdomains.compact.each do |subdomain|
              raise ArgumentError, "Illegal subdomain: #{subdomain.inspect}" unless subdomain.to_s =~ /^[0-9a-z\-]+$/
            end
            if subdomains.include? nil
              raise ArgumentError, "Can't specify a nil subdomain unless you set Config.domain_length!" unless Config.domain_length
            end
            name = options.has_key?(:name) ? options.delete(:name) : subdomains.compact.first
            subdomain_options = { :subdomains => subdomains }
          end
          subdomain_options.merge! :name_prefix => "#{name}_", :namespace => "#{name}/" unless name.blank?
          with_options(subdomain_options.merge(options), &block)
        end
        alias_method :subdomains, :subdomain
      end

      def self.included(base)
        base.alias_method_chain :extract_request_environment, :subdomain
        base.alias_method_chain :add_route, :subdomains
      end
      
      def extract_request_environment_with_subdomain(request)
        extract_request_environment_without_subdomain(request).merge(:subdomain => subdomain_for_host(request.host))
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
    end
  
    module Route
      def self.included(base)
        base.alias_method_chain :recognition_conditions, :subdomains
      end
      
      def recognition_conditions_with_subdomains
        result = recognition_conditions_without_subdomains
        # result << "conditions[:subdomains].map(&:to_s).include?(env[:subdomain].to_s)" if conditions[:subdomains]
        case conditions[:subdomains]
        when Array
          result << "conditions[:subdomains].map(&:to_s).include?(env[:subdomain].to_s)"
        when Hash
          result << "(self.send(conditions[:subdomains][:proc], env[:subdomain]) == true)"
        end
        result
      end
    end
  end
end

ActionController::Routing::RouteSet::Mapper.send :include, SubdomainRoutes::Routing::RouteSet::Mapper
ActionController::Routing::RouteSet.send :include, SubdomainRoutes::Routing::RouteSet
ActionController::Routing::Route.send :include, SubdomainRoutes::Routing::Route
