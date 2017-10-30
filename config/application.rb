require File.expand_path('../boot', __FILE__)

require 'rails/all'

# TODO: REMOVE THIS IN PRODUCTION APP!
# require 'openssl'
# OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

# Load as otherwise ENV['GOOGLE KEYS'] were being rendered as text rather than getting the variable
Dotenv::Railtie.load

module Researchdatayork
  class Application < Rails::Application
    config.generators do |g|
      g.test_framework :rspec, spec: true
    end

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Do not swallow errors in after_commit/after_rollback callbacks.
    config.active_record.raise_in_transactional_callbacks = true
    # handle 404 and 500 errors dynamically
    config.exceptions_app = ->(env) { ErrorsController.action(:show).call(env) }
    # use 'delayed_job' as the background job processor
    config.active_job.queue_adapter = :delayed_job
  end
end
