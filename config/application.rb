require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)
require 'csv'

module Puzzletime
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    config.autoload_paths += %W(#{config.root}/app/domain/forms
                                #{config.root}/app/domain/reports
                                #{config.root}/app/models/util
                                #{config.root}/app/domain/evaluations
                                #{config.root}/app/domain/graphs
                                #{config.root}/app/domain
                                #{config.root}/app/jobs)

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'
    config.time_zone = 'Bern'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    config.i18n.default_locale = :'de-CH'

    config.encoding = "utf-8"

    config.cache_store = :dalli_store

    config.middleware.insert_before Rack::ETag, Rack::Deflater

    config.assets.precompile += %w(print.css phone.css *.png *.gif *.jpg *.svg)

    config.assets.paths << Rails.root.join('app', 'assets', 'fonts')

    config.to_prepare do |_|
      if Settings.highrise.api_token
        Crm.instance = Crm::Highrise.new
        if Delayed::Job.table_exists?
          CrmSyncJob.new.schedule
        end
      end
    end
  end

  def self.version
    @@ptime_version ||=
      if File.exists?("#{Rails.root}/VERSION")
        File.open("#{Rails.root}/VERSION").first.chomp
      else
        ''
      end
  end
end
