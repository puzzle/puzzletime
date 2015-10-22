source 'https://rubygems.org'

gem 'rails', '4.2.4'

gem 'pg'

gem 'airbrake'
gem 'acts_as_tree'
gem 'cancancan', '< 1.13' # higher requires ruby 2.0
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
gem 'protective'
gem 'rails_autolink'
gem 'config'
gem 'rails-i18n'
gem 'net-ldap'
gem 'seed-fu'
gem 'codez-validates_by_schema', require: 'validates_by_schema'
gem 'validates_timeliness'


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
gem 'selectize-rails', '0.9.1' # newer needs fix for create order


group :development, :test do
  gem 'binding_of_caller'
  gem 'codez-tarantula', require: 'tarantula-rails3'
  gem 'faker'
  gem 'pry-rails'
end

group :development do
  gem 'spring'
  gem 'better_errors', '< 2.0.0' # higher requires ruby 2.0
  gem 'bullet'
  gem 'quiet_assets'
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
end

group :console do
  gem 'pry-doc'
  gem 'pry-nav'
  gem 'pry-debugger', platforms: :ruby_19, require: ENV['RM_INFO'].to_s.empty?
  gem 'pry-byebug', platforms: [:ruby_20], require: ENV['RM_INFO'].to_s.empty?
end

group :metrics do
  gem 'annotate'
  gem 'brakeman' # , '2.5.0'
  gem 'minitest-reporters'
  gem 'rails-erd'
  gem 'rubocop'
  gem 'rubocop-checkstyle_formatter', require: false
  gem 'simplecov-rcov'
  gem 'sdoc'
end
