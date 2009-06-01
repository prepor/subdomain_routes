module SubdomainRoutes
  module Routing
    module RouteSet
      module Mapper
        def subdomain(*subdomains, &block)
          options = subdomains.extract_options!
          if subdomains.empty?
            if subdomain = options.delete(:resources)
              resources = subdomain.to_s.downcase.pluralize
              raise ArgumentError, "Invalid resource name" if resources.blank? # TODO: test this!
              subdomain_options = { :subdomains => { :resources => resources }, :name_prefix => "#{resources.singularize}_" }
              named_route resources, "/", :controller => resources, :action => "index", :conditions => { :method => :get }, :requirements => { :subdomains => [""] }
              # TODO: only map ^^^ this route ^^^ if domain_length is set!
              named_route resources.singularize, "/", :controller => resources, :action => "show", :conditions => { :method => :get }, :subdomains => { :resources => resources }
              # TODO: consider :only, :except options!
            else
              raise ArgumentError, "Please specify at least one subdomain!"
            end
          else
            subdomains.map!(&:to_s)
            subdomains.map!(&:downcase)
            subdomains.uniq!
            subdomains.compact.each do |subdomain|
              raise ArgumentError, "Illegal subdomain format: #{subdomain.inspect}" unless subdomain.blank? || SubdomainRoutes.valid_subdomain?(subdomain)
            end
            if subdomains.include? ""
              raise ArgumentError, "Can't specify a nil subdomain unless you set Config.domain_length!" unless Config.domain_length
            end
            subdomain_options = { :subdomains => subdomains }
            name = subdomains.reject(&:blank?).first
            name = options.delete(:name) if options.has_key?(:name)
            name = name.to_s.downcase.gsub(/[^(a-z0-9)]/, ' ').squeeze(' ').strip.gsub(' ', '_') unless name.blank?
            subdomain_options.merge! :name_prefix => "#{name}_", :namespace => "#{name}/" unless name.blank?
          end
          with_options(subdomain_options.merge(options), &block)
        end
        alias_method :subdomains, :subdomain
      end
    end
  end
end

ActionController::Routing::RouteSet::Mapper.send :include, SubdomainRoutes::Routing::RouteSet::Mapper

