module SubdomainRoutes
  module UrlWriter
    def self.included(base)
      base.alias_method_chain :url_for, :subdomains
    end

    def url_for_with_subdomains(options)
      if subdomain = options.delete(:subdomain)
        host = options[:host] || default_url_options[:host]
        raise "Missing host to link to! Please provide :host parameter or set default_url_options[:host]" unless host
        first_part, *other_parts = host.split(".")
        if subdomain.to_s != first_part
          options[:only_path] = false
          options[:host] = other_parts.unshift(subdomain).join('.')
        end
      end
      url_for_without_subdomains(options)
    end
  end
end

ActionController::UrlWriter.send :include, SubdomainRoutes::UrlWriter
