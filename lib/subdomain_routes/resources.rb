module StaticSubdomains
  module Resources
    def self.included(base)
      base.alias_method_chain :action_options_for, :subdomains
      base::INHERITABLE_OPTIONS << :subdomains
    end
    
    def action_options_for_with_subdomains(action, resource, *args)
      action_options_for_without_subdomains(action, resource, *args).merge(:subdomains => resource.options[:subdomains])
    end
    private :action_options_for_with_subdomains
  end
end

ActionController::Resources.send :include, StaticSubdomains::Resources



# # 
# # This alternative also works. It duplicates code in add_route_with_subdomains (in routing.rb) so is not
# # so good that way, but has the benefit of not modifying ActionController::Resources#action_options_for,
# # which is a private method.
# # 
# module StaticSubdomains
#   module Resources
#     module Resource
#       def self.included(base)
#         base.alias_method_chain :conditions, :subdomains
#         base.alias_method_chain :requirements, :subdomains
#       end
#       
#       def conditions_with_subdomains
#         @options[:subdomains] ?
#           conditions_without_subdomains.merge(:subdomains => @options[:subdomains]) :
#           conditions_without_subdomains
#       end
#       
#       def requirements_with_subdomains(with_id = false)
#         @options[:subdomains] && @options[:subdomains].size == 1 ?
#           requirements_without_subdomains(with_id).merge(:subdomain => @options[:subdomains].first) :
#           requirements_without_subdomains(with_id)
#       end
#     end
#   end
# end
# 
# ActionController::Resources::INHERITABLE_OPTIONS << :subdomains
# ActionController::Resources::Resource.send :include, StaticSubdomains::Resources::Resource
