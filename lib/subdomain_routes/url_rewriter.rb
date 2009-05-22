# module SubdomainRoutes
#   module UrlRewriter
#     def self.included(base)
#       base.alias_method_chain :rewrite, :subdomains
#       base::RESERVED_OPTIONS << :subdomain
#     end
#     
#     def rewrite_with_subdomains(options)
#       if subdomain = options.delete(:subdomain)
#         first_part, *other_parts = (options[:host] || @request.host).split(".")
#         ## TODO: refactor this code to share with UrlWriter
#         case subdomain
#         when Array
#           unless subdomain.find { |sub| sub.to_s == first_part }
#             raise ActionController::RoutingError, "route for #{options.inspect} failed to generate, expected subdomain: #{subdomain.inspect}, instead got: #{first_part}"
#           end
#         else
#           if subdomain.to_s != first_part
#             options[:only_path] = false
#             options[:host] = other_parts.unshift(subdomain).join('.')
#           end
#         end
#       end
#       rewrite_without_subdomains(options)
#     end
#   end
# end
# 
# ActionController::UrlRewriter.send :include, SubdomainRoutes::UrlRewriter
