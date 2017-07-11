source 'https://rubygems.org'

gem 'rails', '5.0.4'

gem 'pg'

gem 'airbrake'
gem 'acts_as_tree'
gem 'cancancan'
gem 'config'
gem 'country_select'
gem 'daemons'
gem 'dalli'
gem 'delayed_job_active_record'
gem 'delayed_cron_job'
gem 'kaminari'
gem 'kaminari-bootstrap'
gem 'haml'
gem 'highrise'
gem 'jbuilder'
gem 'nested_form_fields'
gem 'net-ldap'
gem 'nokogiri'
gem 'protective'
gem 'rails_autolink'
gem 'rails-i18n'
gem 'request_store'
gem 'rqrcode'
gem 'seed-fu'
gem 'validates_by_schema'
gem 'validates_timeliness'
gem 'paper_trail'

## assets
gem 'sass-rails'
gem 'uglifier'
gem 'coffee-rails'
gem 'therubyracer', platforms: :ruby

gem 'jquery-rails'
gem 'jquery-ui-rails'
gem 'turbolinks'
gem 'jquery-turbolinks'
gem 'bootstrap-sass'
gem 'selectize-rails'

group :development, :test do
  gem 'binding_of_caller'
  gem 'codez-tarantula', require: 'tarantula-rails3'
  gem 'faker'
  gem 'pry-rails'
  gem 'request_profiler'
end

group :development do
  gem 'puma'
  gem 'spring'
  #gem 'better_errors'
  gem 'bullet'
end

group :test do
  gem 'fabrication'
  gem 'mocha', require: false
  gem 'capybara'
  gem 'headless'
  gem 'selenium-webdriver'
  gem 'database_cleaner'
  gem 'm'
  gem 'gemsurance'
  gem 'rails-controller-testing'
end

group :console do
  gem 'pry-doc'
  gem 'pry-nav'
  gem 'pry-byebug', require: ENV['RM_INFO'].to_s.empty?
end

group :metrics do
  gem 'annotate'
  gem 'brakeman'
  gem 'minitest-reporters'
  gem 'rails-erd'
  gem 'rubocop', '< 0.42' # higher requires ruby 2.0
  gem 'rubocop-checkstyle_formatter', require: false
  gem 'simplecov-rcov'
  gem 'sdoc'
end
