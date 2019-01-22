#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)
require 'csv'

require_relative 'version'

module Puzzletime
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2


    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

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
    # Attention: Setting a time zone here will confuse OpenShift.
    # We leave the Time zone on UTC as recommended by
    # https://robots.thoughtbot.com/its-about-time-zones
    # config.time_zone = 'Bern'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    config.i18n.default_locale = :'de-CH'

    config.encoding = 'utf-8'

    memcached_host = ENV['RAILS_MEMCACHED_HOST'] || 'localhost'
    memcached_port = ENV['RAILS_MEMCACHED_PORT'] || '11211'
    config.cache_store = :dalli_store, "#{memcached_host}:#{memcached_port}"

    config.middleware.insert_before Rack::ETag, Rack::Deflater

    config.active_record.time_zone_aware_types = [:datetime, :time]

    config.to_prepare do |_|
      Crm.init
      Invoicing.init
    end
  end

  def self.version
    @@ptime_version ||= build_version
  end

  def self.changelog_url
    @@ptime_changelog_url ||= 'https://github.com/puzzle/puzzletime/blob/master/CHANGELOG.md'
  end

  private
  def self.build_version
    major_and_minor = Puzzletime::VERSION

    patch_and_build_info =
      if File.exists?("#{Rails.root}/BUILD_INFO")
        File.open("#{Rails.root}/BUILD_INFO").first.chomp
      else
        ''
      end

    "#{major_and_minor}#{patch_and_build_info}"
  end
end
