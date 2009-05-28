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
    
    def generate(name, request, context)
      raise("no generator for subdomain #{name.inspect}") unless generates?(name)
      args = case @generators[name].arity
      when 1 then request ? [ request ] : raise("couldn't find a @request!")
      else [ request, context ]
      end
      @generators[name].call(*args)
    rescue Exception => e
      raise ActionController::RoutingError, "Route failed to generate (#{e.message})"
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
