# Be sure to restart your web server when you modify this file.

# Uncomment below to force Rails into production mode when 
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.0.2'

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

PATH_PREFIX = ENV['RAILS_RELATIVE_URL_ROOT'] || ''

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence those specified here
  
  # Skip frameworks you're not going to use (only works if using vendor/rails)
  # config.frameworks -= [ :action_web_service, :action_mailer ]

  # Add additional load paths for your own custom dirs
  config.load_paths += %W( #{RAILS_ROOT}/app/models/forms 
                           #{RAILS_ROOT}/app/models/modules 
                           #{RAILS_ROOT}/app/models/util 
                           #{RAILS_ROOT}/app/models/evaluations
                           #{RAILS_ROOT}/app/models/graphs
                           #{RAILS_ROOT}/app/models/puzzlebase)

  # Force all environments to use the same logger level 
  # (by default production uses :info, the others :debug)
  # config.log_level = :debug

  # Use the database for sessions instead of the file system
  # (create the session table with 'rake db:sessions:create')
  config.action_controller.session_store = :mem_cache_store
  config.action_controller.session = { :session_key => "ruby_sess",
                                       :secret => "this is the very secret phrase to encrypt my sessions" }

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper, 
  # like if you have constraints or database-specific column types
  # config.active_record.schema_format = :sql

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector

  # Make Active Record use UTC-base instead of local time
  # config.active_record.default_timezone = :utc
    
  # See Rails::Configuration for more options
  config.action_controller.asset_host = PATH_PREFIX
  
  # Do not symbolize keys for performance reasons
  config.action_view.local_assigns_support_string_keys = false
end

# Add new inflection rules using the following format 
# (all these examples are active by default):
# Inflector.inflections do |inflect|
#   inflect.plural /^(ox)$/i, '\1en'
#   inflect.singular /^(ox)en/i, '\1'
#   inflect.irregular 'person', 'people'
#   inflect.uncountable %w( fish sheep )
# end

# Include your application configuration below
ActionMailer::Base.delivery_method = :sendmail

ActionController::Base.fragment_cache_store = :mem_cache_store

require 'overrides' 
require 'report_type'
require 'puzzletime_settings'
#require 'memcache'
