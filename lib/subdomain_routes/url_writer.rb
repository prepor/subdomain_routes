module SubdomainRoutes
  class HostNotSupplied < StandardError
  end
  
  module RewriteSubdomainOptions
    include SplitHost
    
    def subdomain_procs
      ActionController::Routing::Routes.subdomain_procs
    end

    def rewrite_subdomain_options(options, host)
      if subdomains = options[:subdomains]
        old_subdomain, domain = split_host(host)
        new_subdomain = options.has_key?(:subdomain) ? options[:subdomain].to_s.downcase : old_subdomain
        begin
          case subdomains
          when Array
            unless subdomains.include? new_subdomain
              if subdomains.size > 1 || options.has_key?(:subdomain)
                raise ActionController::RoutingError, "expected subdomain in #{subdomains.inspect}, instead got subdomain #{new_subdomain.inspect}"
              else
                new_subdomain = subdomains.first
              end
            end
          when Hash
            name = subdomains[:proc]
            if subdomain_procs.generates?(name)
              raise ActionController::RoutingError, "can't specify a subdomain for this route" if options.has_key?(:subdomain)
              new_subdomain = subdomain_procs.generate(name, @request, options.delete(:context)).to_s.downcase
              unless subdomain_procs.verify(name, new_subdomain) && new_subdomain =~ SUBDOMAIN_FORMAT
                raise ActionController::RoutingError, "generated subdomain #{new_subdomain.inspect} is invalid"
              end
            elsif subdomain_procs.verify(name, new_subdomain)
            else
              raise ActionController::RoutingError, "subdomain #{new_subdomain.inspect} is invalid"
            end
          end
        rescue ActionController::RoutingError => e
          raise ActionController::RoutingError, "Route for #{options.inspect} failed to generate (#{e.message})"
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
      [ :rewrite, :initialize ].each { |method| base.alias_method_chain method, :subdomains }
      base::RESERVED_OPTIONS << :subdomain
    end
    
    def initialize_with_subdomains(*args)
      ActionController::Routing::Routes.subdomain_procs.flush! unless SubdomainRoutes::Config.manual_flush
      initialize_without_subdomains(*args)
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

if defined? ActionMailer::Base
  ActionMailer::Base.send :include, ActionController::UrlWriter
end
