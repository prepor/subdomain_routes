module SubdomainRoutes
  module UrlWriter
    def self.included(base)
      base.alias_method_chain :url_for, :subdomains
    end

    def url_for_with_subdomains(options)
      first_part, *other_parts = options[:host].split(".")
      if subdomain = options.delete(:subdomain)
        if subdomain.to_s != first_part
          options[:only_path] = false
          options[:host] = other_parts.unshift(subdomain).join('.')
        end
      end
      url_for_without_subdomains(options)
    end
  end
  
  module UrlRewriter
    def self.included(base)
      base.alias_method_chain :rewrite, :subdomains
      base::RESERVED_OPTIONS << :subdomain
    end
    
    def rewrite_with_subdomains(options)
      first_part, *other_parts = (options[:host] || @request.host).split(".")
      if subdomain = options.delete(:subdomain)
        if subdomain.to_s != first_part
          options[:only_path] = false
          options[:host] = other_parts.unshift(subdomain).join('.')
        end
      end
      rewrite_without_subdomains(options)
    end
  end
end

ActionController::UrlWriter.send :include, SubdomainRoutes::UrlWriter
ActionController::UrlRewriter.send :include, SubdomainRoutes::UrlRewriter

