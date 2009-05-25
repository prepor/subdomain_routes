module SubdomainRoutes
  module Config
    mattr_accessor :domain_length
    
    def self.subdomain_proc(method, &block)
      mod = Module.new do
        define_method(method, &block)
      end
      ActionController::UrlWriter.send :include, mod
      ActionController::UrlRewriter.send :include, mod
      ActionController::Routing::Route.send :include, mod
    end
  end
end