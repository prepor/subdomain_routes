module SubdomainRoutes
  def self.process_options(options, host)
    if subdomains = options.delete(:subdomains)
      first_part, *other_parts = host.split('.')
      if subdomains.size > 1
        unless subdomains.map(&:to_s).find { |sub| first_part == sub }
          raise ActionController::RoutingError, "route for #{options.merge(:subdomains => subdomains).inspect} failed to generate, expected subdomain in: #{subdomains.inspect}, instead got subdomain: #{first_part}"
        end
        ## TODO: eventually some code in here for setting user-specified :subdomain (if it matches) ???
        ## (write specs first!)
      else
        if first_part != subdomains.first.to_s
          options[:only_path] = false
          options[:host] = other_parts.unshift(subdomains.first).join('.')
        end
        ## TODO: eventually some code in here for setting user-specified :subdomain (if it matches) ???
        ## (write specs first!)
      end
    end
  end
    
  module UrlWriter
    def self.included(base)
      base.alias_method_chain :url_for, :subdomains
    end

    def url_for_with_subdomains(options)
      host = options[:host] || default_url_options[:host]
      # TODO: only raise this error if needed! maybe move to process_options?
      raise "Missing host to link to! Please provide :host parameter or set default_url_options[:host]" unless host
      SubdomainRoutes::process_options(options, host)
      url_for_without_subdomains(options)
    end
  end

  module UrlRewriter
    def self.included(base)
      base.alias_method_chain :rewrite, :subdomains
      base::RESERVED_OPTIONS << :subdomains
    end
    
    def rewrite_with_subdomains(options)
      host = options[:host] || @request.host
      SubdomainRoutes::process_options(options, host)
      rewrite_without_subdomains(options)
    end
  end
end

ActionController::UrlWriter.send :include, SubdomainRoutes::UrlWriter
ActionController::UrlRewriter.send :include, SubdomainRoutes::UrlRewriter
