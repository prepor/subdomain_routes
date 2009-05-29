describe "ActionMailer::Base" do
  before(:each) do
    @mailer_class = Class.new(ActionMailer::Base) { def test; body "test"; end }
  end
  it "should flush the subdomain procs cache each time a mailer is created" do
    ActionController::Routing::Routes.subdomain_procs.should_receive(:flush!)
    @mailer_class.create_test
  end

  it "should not flush the subdomain procs cache if SubdomainRoutes::Config.manual_flush is set" do
    SubdomainRoutes::Config.stub!(:manual_flush).and_return(true)
    ActionController::Routing::Routes.subdomain_procs.should_not_receive(:flush!)
    @mailer_class.create_test
  end
end