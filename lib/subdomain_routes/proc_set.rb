module SubdomainRoutes
  class ProcSet
    extend ActiveSupport::Memoizable
    
    def initialize
      clear!
    end
    
    def add_recognizer(name, &block)
      @recognizers[name] = block
    end

    def add_generator(name, &block)
      @generators[name] = block
    end
    
    def recognizes?(name)
      @recognizers.has_key?(name)
    end

    def generates?(name)
      @generators.has_key?(name)
    end
    
    def recognize(name, subdomain)
      @recognizers[name].call(subdomain) if recognizes?(name)
    end
    
    def generate(name, request, context)
      raise("no generator for subdomain #{name.inspect}") unless generates?(name)
      args = case @generators[name].arity
      when -1, 0 then [ ]
      when 1 then request ? [ request ] : raise("couldn't find a @request!")
      else [ request, context ]
      end
      @generators[name].call(*args)
    end
    
    memoize :recognize
    private :flush_cache
    
    def flush!
      flush_cache :recognize
    end
    
    def clear!
      @recognizers = {}
      @generators = {}
      flush!
    end
  end
end
