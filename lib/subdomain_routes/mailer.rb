module SubdomainRoutes
  module MailerMethods
    def self.included(base)
      base.alias_method_chain :create!, :subdomains
    end
    
    def create_with_subdomains!(*args)
      ActionController::Routing::Routes.subdomain_procs.flush! unless SubdomainRoutes::Config.manual_flush
      create_without_subdomains!(*args)
    end
  end
end

if defined? ActionMailer::Base
  ActionMailer::Base.send :include, SubdomainRoutes::MailerMethods
end

