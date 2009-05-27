module SubdomainRoutes
  class ProcSet
    extend ActiveSupport::Memoizable
    
    def initialize
      clear!
    end
    
    def add_verifier(name, &block)
      @verifiers[name] = block
    end

    def add_generator(name, &block)
      @generators[name] = block
    end
    
    def verifies?(name)
      @verifiers.has_key?(name)
    end

    def generates?(name)
      @generators.has_key?(name)
    end
    
    def verify(name, subdomain)
      @verifiers[name].call(subdomain) if verifies?(name)
    end
    
    def generate(name, options)
      generates?(name) ? @generators[name].call(options) : raise("can't generate subdomain #{name.inspect}")
    rescue Exception => e
      raise ActionController::RoutingError, "route failed to generate: #{e.message}"
    end
    
    memoize :verify
    private :flush_cache
    
    def flush!
      flush_cache :verify
    end
    
    def clear!
      @verifiers = {}
      @generators = {}
      flush!
    end
  end
end
