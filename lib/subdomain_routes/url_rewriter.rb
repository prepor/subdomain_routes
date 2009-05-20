# module SubdomainRoutes
#   module UrlRewriter  
#     def self.included(base)
#       base.alias_method_chain :rewrite_url, :subdomains
#     end
# 
#     def rewrite_url_with_subdomains(options)
#       if subdomain = options.delete(:subdomain)
#         first_part, *other_parts = (options[:host] || @request.host).split(".")
#         if subdomain.to_s != first_part
#           options[:only_path] = false
#           options[:host] = "#{subdomain}.#{other_parts.join('.')}"
#         end
#       end
#       rewrite_url_without_subdomains(options)
#     end
#   end
# end
# 
# ActionController::UrlRewriter.send :include, SubdomainRoutes::UrlRewriter
# 
