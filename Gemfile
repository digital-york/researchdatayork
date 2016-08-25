source 'https://rubygems.org'


gem 'dlibhydra', :git => 'git://github.com/digital-york/dlibhydra.git', branch: 'datasetsv2'
gem 'puree', '0.14.0'
gem 'active_fedora-noid'
gem 'browse-everything'
#gem 'hydra', '9.1.0'
gem 'hydra', :git => 'https://github.com/projecthydra/hydra.git', tag: 'v9.1.0.rc3'
gem 'hydra-works', '0.7.0'
gem 'dotenv-rails', :groups => [:development, :test, :production]
gem 'faraday'
gem 'qa'
# include http_headers gem for parsing http headers
gem 'http_headers'
# include rubyzip to handle unzipping of uploaded zip files
gem 'rubyzip'
# include Nokogiri for parsing XML
gem 'nokogiri'
# include the Google Drive API for browsing user's Google Drive files
gem 'google-api-client', require: 'google/apis/drive_v3'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '4.2.6'
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
gem 'jquery-ui-rails'
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
  gem 'spring'
end


group :development, :test do
  #gem 'solr_wrapper', '>= 0.3'
  gem 'solr_wrapper', '>= 0.13.2'
end

gem 'rsolr', '~> 1.0.6'
gem 'globalid'
gem 'devise'
gem 'devise-guests', '~> 0.3'
group :development, :test do
  gem 'fcrepo_wrapper'
  gem 'rspec-rails'
  gem 'awesome_print', :require => 'ap' 
end

# hack - include a specific version of "stomp" (required by hydra gem) because the default (latest) version has buggy circular dependencies
gem 'stomp', '1.4.1'
