source 'https://rubygems.org'

gem 'rails', '~> 5.2.x'

gem 'pg', '= 0.21.0'

gem 'acts_as_tree'
gem 'bleib'
gem 'bootsnap'
gem 'cancancan'
gem 'config'
gem 'country_select'
gem 'daemons'
gem 'dalli'
gem 'delayed_cron_job'
gem 'delayed_job_active_record'
gem 'devise'
gem 'fast_jsonapi'
gem 'haml'
gem 'highrise'
gem 'image_processing'
gem 'jbuilder'
gem 'kaminari'
gem 'kaminari-bootstrap'
gem 'nested_form_fields'
gem 'net-ldap'
gem 'nokogiri'
gem 'omniauth'
gem 'omniauth-keycloak'
gem 'omniauth-saml'
gem 'prawn'
gem 'prometheus_exporter'
gem 'protective'
gem 'puma'
gem 'rails-i18n'
gem 'rails_autolink'
gem 'request_store'
gem 'rqrcode'
gem 'rswag-ui'
gem 'seed-fu'
gem 'swagger-blocks'
gem 'validates_by_schema'
gem 'validates_timeliness'

# Error reporting, they are required in their respective initializers
gem 'airbrake', require: false
gem 'sentry-raven', require: false

# must be at the end
gem 'paper_trail'

## assets
gem 'autoprefixer-rails'
gem 'coffee-rails'

# Using mini_racer instead of nodejs, because of errors on Jenkins.
# mini_racer can only be built with gcc >= 4.7. Our Jenkins uses 4.4.7
gem 'mini_racer'
gem 'sass-rails', '~> 5'
gem 'uglifier'

# Locked to 3.3.x, because 3.4.0 expects sassc, which can only be built with gcc
# >= 4.6. Our Jenkins uses 4.4.7
gem 'bootstrap-sass'
gem 'chartjs-ror'
gem 'jquery-rails'
gem 'jquery-ui-rails'
gem 'selectize-rails'
gem 'turbolinks'

group :development, :test do
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'codez-tarantula', require: 'tarantula-rails3'
  gem 'faker'
  gem 'pry-rails'
  gem 'request_profiler'
end

group :development do
  gem 'bullet'
  gem 'spring'
  gem 'web-console'
end

group :test do
  gem 'bundler-audit'
  gem 'capybara'
  gem 'database_cleaner'
  gem 'fabrication'
  gem 'headless'
  gem 'mocha', require: false
  gem 'rails-controller-testing'
  gem 'selenium-webdriver'
  gem 'webdrivers'
end

group :console do
  gem 'pry-byebug', require: ENV['RM_INFO'].to_s.empty?
  gem 'pry-doc'
end

group :metrics do
  gem 'annotate'
  gem 'brakeman'
  gem 'haml-lint'
  gem 'minitest-reporters'
  gem 'rails-erd'
  gem 'rubocop'
  gem 'rubocop-checkstyle_formatter', require: false
  gem 'rubocop-minitest'
  gem 'rubocop-performance'
  gem 'rubocop-rails'
  gem 'sdoc'
  gem 'simplecov-rcov', git: 'https://github.com/puzzle/simplecov-rcov'
end
