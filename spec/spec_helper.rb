require 'spec'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'subdomain_routes'

Spec::Runner.configure do |config|
  
end

include ActionController::UrlWriter