module SubdomainRoutes
  module Request
    include SplitHost
    
    def subdomain
      subdomain_for_host(host)
      # TODO: catch HostNotSupplied and TooManySubdomains and deal with them somehow!
    end
  end
end

ActionController::Request.send :include, SubdomainRoutes::Request