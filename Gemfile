source 'https://rubygems.org'

gem 'curation_concerns', '>= 1.7.0'
gem 'dlibhydra', git: 'https://github.com/digital-york/dlibhydra.git'
gem 'puree', '0.17.0'
gem 'active_fedora-noid'
# force app to use the latest possible 'browse everything' to resolve a dependency dispute between curation_concerns and google_api_client
gem 'browse-everything', git: 'https://github.com/projecthydra/browse-everything.git'
# gem 'hydra', '9.1.0'
#gem 'hydra' #, git: 'https://github.com/projecthydra/hydra.git', tag: 'v9.1.0.rc3'
#gem 'hydra-works' #, '0.7.0'
gem 'dotenv-rails', groups: [:development, :test, :production]
gem 'faraday'
gem 'qa'
# include http_headers gem for parsing http headers
gem 'http_headers'
# include rubyzip to handle unzipping of uploaded zip files
gem 'rubyzip'
# include Nokogiri for parsing XML
gem 'nokogiri'
# include the Google Drive API for browsing user's Google Drive files
gem 'google-api-client', '~> 0.9' # require: 'google/apis/drive_v3'
# include library to enabling shibboleth authentication
gem 'omniauth-shibboleth'
# include 'browser' to help us detect whether requests are coming from humans or bots
gem 'browser'
# include 'delayed_job' to allow us to run commands asyncronously, in the background (e.g. sending email)
gem 'delayed_job_active_record'
# include 'daemons' so that we can run the delayed_job daemon
gem 'daemons'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '4.2.7.1'
# Use sqlite3 as the database for Active Record
gem 'sqlite3'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.1.0'
# See https://github.com/rails/execjs#readme for more supported runtimes
gem 'therubyracer', platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails'
# and add the jquery UI libraries as well
gem 'jquery-ui-rails', '5.0.5'
# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.0'
# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.0', group: :doc

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Unicorn as the app server
# gem 'unicorn'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug'
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'web-console', '~> 2.0'

  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  # gem 'spring'
end

group :development, :test do
  gem 'solr_wrapper', '>= 0.13.2'
end

gem 'rsolr' #, '~> 1.0.6'
gem 'globalid'
gem 'devise'
gem 'devise-guests', '~> 0.3'
group :development, :test do
  gem 'fcrepo_wrapper'
  gem 'rspec-rails'
  gem 'awesome_print', require: 'ap'
end

# HACK: - include a specific version of "stomp" (required by hydra gem) because the default (latest) version has buggy circular dependencies
gem 'stomp', '1.4.1'
