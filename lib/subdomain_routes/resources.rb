module StaticSubdomains
  module Resources
    module Resource
      def self.included(base)
        base.alias_method_chain :conditions, :subdomains
        base.alias_method_chain :requirements, :subdomains
      end
      
      def conditions_with_subdomains
        @options[:subdomains] ?
          conditions_without_subdomains.merge(:subdomains => @options[:subdomains]) :
          conditions_without_subdomains
      end
      
      def requirements_with_subdomains(with_id = false)
        @options[:subdomains] && @options[:subdomains].size == 1 ?
          requirements_without_subdomains(with_id).merge(:subdomain => @options[:subdomains].first) :
          requirements_without_subdomains(with_id)
      end
    end
  end
end

ActionController::Resources::INHERITABLE_OPTIONS << :subdomains
ActionController::Resources::Resource.send :include, StaticSubdomains::Resources::Resource
