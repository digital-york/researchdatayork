# Load the Rails application.
require File.expand_path('../application', __FILE__)

# Initialize the Rails application.
Rails.application.initialize!

# configure mail settings
ActionMailer::Base.delivery_method = :smtp
ActionMailer::Base.perform_deliveries = true
ActionMailer::Base.default_url_options = { host: ENV["HOST"] } 
ActionMailer::Base.smtp_settings = {
   address: 'smtp.york.ac.uk',
   port: 25
}
