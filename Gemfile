source 'https://rubygems.org'

gem 'rails', '~> 5.2.x'

gem 'pg'

gem 'nochmal', github: 'puzzle/nochmal'

gem 'acts_as_tree'
gem 'aws-sdk-s3', require: false
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
gem 'influxdb-client'
gem 'influxdb-client-apis'
gem 'jbuilder'
gem 'kaminari'
gem 'kaminari-bootstrap'
gem 'nested_form_fields'
gem 'net-ldap'
gem 'nokogiri'
gem 'omniauth'
gem 'omniauth-keycloak'
gem 'omniauth-rails_csrf_protection'
gem 'omniauth-saml'
gem 'prawn'
gem 'prometheus_exporter'
gem 'protective'
gem 'puma'
gem 'rails_autolink'
gem 'rails-i18n'
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

## assets
gem 'autoprefixer-rails'
gem 'bootstrap-sass'
gem 'chartjs-ror'
gem 'coffee-rails'
gem 'execjs'
gem 'jquery-rails'
gem 'jquery-ui-rails'
gem 'sass-rails'
gem 'selectize-rails'
gem 'turbolinks'
gem 'uglifier'

# must be at the end
gem 'paper_trail'

group :development, :test do
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'codez-tarantula', require: 'tarantula-rails3'
  gem 'faker'
  gem 'pry-rails'
  gem 'rb-readline'
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
  gem 'webmock'
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
