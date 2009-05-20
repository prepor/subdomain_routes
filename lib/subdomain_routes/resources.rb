module SubdomainRoutes
  module Resources
    def self.included(base)
      base::INHERITABLE_OPTIONS << :subdomains
      base.alias_method_chain :resources, :subdomains
      base.alias_method_chain :resource, :subdomains  
    end
    
    def resources_with_subdomains(*args, &block)
      options = args.extract_options!
      if subdomains = options[:subdomains]
        options[:conditions] ||= {}
        options[:conditions][:subdomains] = subdomains
        unless subdomains.size > 1
          options[:requirements] ||= {}
          options[:requirements][:subdomain] = subdomains.first
        end
      end
      with_options options do |map|
        map.resources_without_subdomains(*args, &block)
      end
    end

    def resource_with_subdomains(*args, &block)
      options = args.extract_options!
      if subdomains = options[:subdomains]
        options[:conditions] ||= {}
        options[:conditions][:subdomains] = subdomains
        unless subdomains.size > 1
          options[:requirements] ||= {}
          options[:requirements][:subdomain] = subdomains.first
        end
      end
      with_options options do |map|
        map.resource_without_subdomains(*args, &block)
      end
    end
  end
end

ActionController::Resources.send :include, SubdomainRoutes::Resources




# module SubdomainRoutes
#   module Resources
#     def self.included(base)
#       base::INHERITABLE_OPTIONS << :subdomains
#       base.alias_method_chain :resources, :subdomains
#       base.alias_method_chain :resource, :subdomains  
#     end
#     
#     def resources_with_subdomains(*args, &block)
#       options = args.extract_options!
#       if subdomains = options[:subdomains]
#         options[:conditions] ||= {}
#         options[:conditions][:subdomains] = subdomains
#         unless subdomains.is_a? Array
#           options[:requirements] ||= {}
#           options[:requirements] = { :subdomain => subdomains }
#         end
#       end
#       with_options options do |map|
#         map.resources_without_subdomains(*args, &block)
#       end
#     end
# 
#     def resource_with_subdomains(*args, &block)
#       options = args.extract_options!
#       if subdomains = options[:subdomains]
#         options[:conditions] ||= {}
#         options[:conditions][:subdomains] = subdomains
#         unless subdomains.is_a? Array
#           options[:requirements] ||= {}
#           options[:requirements] = { :subdomain => subdomains }
#         end
#       end
#       with_options options do |map|
#         map.resource_without_subdomains(*args, &block)
#       end
#     end
#   end
# end
# 
# ActionController::Resources.send :include, SubdomainRoutes::Resources
