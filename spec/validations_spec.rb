describe "subdomain format validation" do
  it "should validate supplied attributes against a subdomain regexp" do
    klass = Class.new { extend SubdomainRoutes::Validations::ClassMethods }
    klass.should_receive(:validates_format_of).with(:subdomain, :with => SubdomainRoutes::NON_EMPTY_SUBDOMAIN_FORMAT)
    klass.validates_subdomain_format_of :subdomain
  end
end