module SubdomainRoutes
            SUBDOMAIN_FORMAT = /^([a-z]|[a-z][a-z0-9]|[a-z]([a-z0-9]|\-[a-z0-9])*|)$/
  NON_EMPTY_SUBDOMAIN_FORMAT = /^([a-z]|[a-z][a-z0-9]|[a-z]([a-z0-9]|\-[a-z0-9])*)$/
  # TODO: could we use URI::parse instead?
        
  module Routing
    module RouteSet
      module Mapper
        def subdomain(*subdomains, &block)
          options = subdomains.extract_options!
          name = nil
          if subdomains.empty?
            if subdomain = options.delete(:proc)
              subdomain_options = { :subdomains => { :proc => subdomain } }
              name = subdomain
            else
              raise ArgumentError, "Please specify at least one subdomain!"
            end
          else
            subdomains.map!(&:to_s)
            subdomains.map!(&:downcase)
            subdomains.uniq!
            subdomains.compact.each do |subdomain|
              raise ArgumentError, "Illegal subdomain format: #{subdomain.inspect}" unless subdomain =~ SUBDOMAIN_FORMAT
            end
            if subdomains.include? ""
              raise ArgumentError, "Can't specify a nil subdomain unless you set Config.domain_length!" unless Config.domain_length
            end
            name = subdomains.reject(&:blank?).first
            subdomain_options = { :subdomains => subdomains }
          end
          name = options.delete(:name) if options.has_key?(:name)
          name = name.to_s.downcase.gsub(/[^(a-z0-9)]/, ' ').squeeze(' ').strip.gsub(' ', '_') unless name.blank?
          subdomain_options.merge! :name_prefix => "#{name}_", :namespace => "#{name}/" unless name.blank?
          with_options(subdomain_options.merge(options), &block)
        end
        alias_method :subdomains, :subdomain
      end
    end
  end
end

ActionController::Routing::RouteSet::Mapper.send :include, SubdomainRoutes::Routing::RouteSet::Mapper

