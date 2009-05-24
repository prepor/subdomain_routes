module SubdomainRoutes
  class TooManySubdomains < StandardError
  end
  
  module SplitHost
    private
    
    def split_host(host)
      raise HostNotSupplied, "Can't set subdomain for an IP address!" if host =~ /\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/
      subdomain_parts = host.split('.')
      domain_parts = [ ]
      Config.domain_length.times { domain_parts.unshift subdomain_parts.pop }
      if subdomain_parts.size > 1
        raise TooManySubdomains, "Multiple subdomains found: #{subdomain_parts.join('.')}. (Have you set SubdomainRoutes::Config.domain_length?)"
      end
      result = [ subdomain_parts.pop, domain_parts.join('.') ]
    end
    
    def domain_for_host(host)
      split_host(host).last
    end
    
    def subdomain_for_host(host)
      split_host(host).first
    end
  end
end