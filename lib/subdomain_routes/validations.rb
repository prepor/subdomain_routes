module SubdomainRoutes
  module Validations
    module ClassMethods
      def validates_subdomain_format_of(*attributes)
        with_options :with => SubdomainRoutes::NON_EMPTY_SUBDOMAIN_FORMAT do |with|
          with.validates_format_of(*attributes)
        end
      end
    end
  end
end

if defined? ActiveRecord::Validations::ClassMethods
  ActiveRecord::Base.send :extend, SubdomainRoutes::Validations::ClassMethods
end