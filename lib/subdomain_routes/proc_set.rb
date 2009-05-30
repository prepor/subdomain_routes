module SubdomainRoutes
  class ProcSet
    extend ActiveSupport::Memoizable
    
    def initialize
      clear!
    end
    
    def add_recognizer(name, &block)
      @recognizers[name] = block
    end

    def recognizes?(name)
      @recognizers.has_key?(name)
    end

    def recognize(name, subdomain)
      @recognizers[name].call(subdomain) if recognizes?(name)
    end
    
    memoize :recognize
    private :flush_cache
    
    def flush!
      flush_cache :recognize
    end
    
    def clear!
      @recognizers = {}
      flush!
    end
  end
end
