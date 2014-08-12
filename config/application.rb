require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)
require 'csv'

module Puzzletime

  def self.version
    @@ptime_version ||=
      if File.exists?("#{Rails.root}/VERSION")
        File.open("#{Rails.root}/VERSION").first.chomp
      else
        ''
      end
  end

  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    config.autoload_paths += %W(#{config.root}/app/models/forms
                                #{config.root}/app/models/reports
                                #{config.root}/app/models/util
                                #{config.root}/app/models/evaluations
                                #{config.root}/app/models/graphs)

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'
    config.time_zone = 'Bern'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    config.i18n.default_locale = :'de-CH'

    config.encoding = "utf-8"

    config.cache_store = :dalli_store

    config.assets.precompile += %w(print.css phone.css graph.css *.png *.gif *.jpg)

    config.assets.paths << Rails.root.join('app', 'assets', 'fonts')

  end
end
