describe "ActiveRecord::Base" do
  it "should have a validates_subdomain_format_of method which validates attributes against a subdomain regexp" do
    klass = Class.new(ActiveRecord::Base)
    klass.should_receive(:validates_format_of).with(:subdomain, :with => SubdomainRoutes::NON_EMPTY_SUBDOMAIN_FORMAT)
    klass.validates_subdomain_format_of :subdomain
  end
end