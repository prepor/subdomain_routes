module SubdomainRoutes
  class HostNotSupplied < StandardError
  end
  
  module RewriteSubdomainOptions
    include SplitHost

    def rewrite_subdomain_options(options, host)
      if subdomains = options[:subdomains]
        old_subdomain, domain = split_host(host)
        new_subdomain = options.has_key?(:subdomain) ? options[:subdomain].to_s : old_subdomain
        case subdomains
        when Array
          unless subdomains.include? new_subdomain
            if subdomains.size > 1 || options.has_key?(:subdomain)
              raise ActionController::RoutingError, "route for #{options.inspect} failed to generate, expected subdomain in: #{subdomains.inspect}, instead got subdomain: #{new_subdomain.inspect}"
            else
              new_subdomain = subdomains.first
            end
          end
        when Hash
          if name = subdomains[:proc]
            if ActionController::Routing::Routes.subdomain_procs.generates?(name)
              raise ActionController::RoutingError, "Can't specify a subdomain for this route" if options.has_key?(:subdomain)
              generate_options = {}
              # TODO: do we want to pass in the request instead of the session?
              # TODO: is the options thing a bit awkward?
              generate_options[:session] = @request.session if @request
              generate_options[:generate] = options.delete(:generate) if options[:generate]
              new_subdomain = ActionController::Routing::Routes.subdomain_procs.generate(name, generate_options).to_s
            elsif ActionController::Routing::Routes.subdomain_procs.verify(name, new_subdomain)
            else
              raise ActionController::RoutingError, "route for #{options.inspect} failed to generate: subdomain #{new_subdomain.inspect} not valid"
            end
          end
        end
        unless new_subdomain == old_subdomain
          options[:only_path] = false
          options[:host] = [ new_subdomain, domain ].reject(&:blank?).join('.')
        end
        options.delete(:subdomains)
        options.delete(:subdomain)
      end
    end
  end
    
  module UrlWriter
    include RewriteSubdomainOptions
    
    def self.included(base)
      base.alias_method_chain :url_for, :subdomains
    end

    def url_for_with_subdomains(options)
      host = options[:host] || default_url_options[:host]
      if options[:subdomains] && host.blank?
        raise HostNotSupplied, "Missing host to link to! Please provide :host parameter or set default_url_options[:host]"
      end
      rewrite_subdomain_options(options, host)
      url_for_without_subdomains(options)
    end
  end

  module UrlRewriter
    include RewriteSubdomainOptions
    
    def self.included(base)
      base.alias_method_chain :rewrite, :subdomains
      base::RESERVED_OPTIONS << :subdomain
    end
    
    def rewrite_with_subdomains(options)      
      host = options[:host] || @request.host
      if options[:subdomains] && host.blank?
        raise HostNotSupplied, "Missing host to link to!"
      end
      rewrite_subdomain_options(options, host)
      rewrite_without_subdomains(options)
    end
  end
end

ActionController::UrlWriter.send :include, SubdomainRoutes::UrlWriter
ActionController::UrlRewriter.send :include, SubdomainRoutes::UrlRewriter
