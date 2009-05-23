module SubdomainRoutes
  def self.process_options(options, host)
    # if subdomains = options.delete(:subdomains)
    if subdomains = options[:subdomains]
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
    
  module UrlWriter
    def self.included(base)
      base.alias_method_chain :url_for, :subdomains
    end

    def url_for_with_subdomains(options)
      host = options[:host] || default_url_options[:host]
      if options[:subdomains] && host.blank?
        raise "Missing host to link to! Please provide :host parameter or set default_url_options[:host]"
      end
      SubdomainRoutes::process_options(options, host)
      url_for_without_subdomains(options)
    end
  end

  module UrlRewriter
    def self.included(base)
      base.alias_method_chain :rewrite, :subdomains
      base::RESERVED_OPTIONS << :subdomain
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
