require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Puzzletime
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    config.autoload_paths += %W(#{config.root}/app/models/forms
                                #{config.root}/app/models/csv
                                #{config.root}/app/models/util
                                #{config.root}/app/models/evaluations
                                #{config.root}/app/models/graphs)

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    config.i18n.default_locale = :de

    config.encoding = "utf-8"

    config.cache_store = :dalli_store

    config.to_prepare do |config|
      # TODO refactor to rails_config
      require 'report_type'
      require "#{Rails.root}/config/puzzletime_settings"
    end
  end
end
