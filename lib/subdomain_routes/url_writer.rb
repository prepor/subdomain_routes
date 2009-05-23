module SubdomainRoutes
  class HostNotSupplied < StandardError
  end
  
  class SubdomainNotAvailable < StandardError
  end
  
  module RewriteSubdomainOptions
    def rewrite_subdomain_options(options, host)
      if subdomains = options.delete(:subdomains)
        first_part, *other_parts = host.split('.')
        subdomain = (options[:subdomain] || first_part).to_s
        unless subdomains.map(&:to_s).include? subdomain
          if subdomains.size > 1 || options[:subdomain]
            raise ActionController::RoutingError, "route for #{options.merge(:subdomains => subdomains).inspect} failed to generate, expected subdomain in: #{subdomains.inspect}, instead got subdomain: #{subdomain}"
          else
            subdomain = subdomains.first
          end
        end
        unless first_part == subdomain
          options[:only_path] = false
          options[:host] = other_parts.unshift(subdomain).join('.')
        end
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
      if @request.host.nil?
        raise SubdomainNotAvailable, "Missing host to link to!"
      elsif @request.host =~ /\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/
        raise SubdomainNotAvailable, "Can't set subdomain for an IP address!"
      end
      host = options[:host] || @request.host
      rewrite_subdomain_options(options, host)
      rewrite_without_subdomains(options)
    end
  end
end

ActionController::UrlWriter.send :include, SubdomainRoutes::UrlWriter
ActionController::UrlRewriter.send :include, SubdomainRoutes::UrlRewriter
