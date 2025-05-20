# frozen_string_literal: true

#  Copyright (c) 2006-2023, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)
require 'csv'

require_relative 'version'

module Puzzletime
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    # FIXME: remove this if it works flawlesly
    config.active_record.belongs_to_required_by_default = false

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    config.autoload_paths += %W[#{config.root}/app/models/util]

    # Use custom error controller
    config.exceptions_app = routes

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'
    # Attention: Setting a time zone here will confuse OpenShift.
    # We leave the Time zone on UTC as recommended by
    # https://robots.thoughtbot.com/its-about-time-zones
    config.time_zone = 'Bern'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    locale =
      if ENV['RAILS_LOCALE']
        :"#{ENV['RAILS_LOCALE']}"
      else
        :'de-CH'
      end
    config.i18n.default_locale = locale

    config.encoding = 'utf-8'

    memcached_host = ENV['RAILS_MEMCACHED_HOST'] || 'localhost'
    memcached_port = ENV['RAILS_MEMCACHED_PORT'] || '11211'
    config.cache_store = :mem_cache_store, "#{memcached_host}:#{memcached_port}"

    config.middleware.insert_before Rack::ETag, Rack::Deflater

    config.active_record.time_zone_aware_types = %i[datetime time]

    config.active_job.queue_adapter = :delayed_job

    config.action_mailer.default_url_options = {
      protocol: 'https',
      host: ENV['RAILS_MAIL_URL_HOST'].presence || 'example.com'
    }

    config.to_prepare do |_|
      Crm.init
      Invoicing.init
      CommitReminderJob.schedule
    rescue ActiveRecord::NoDatabaseError
    rescue ActiveRecord::StatementInvalid => e
      # the db might not exist yet, lets ignore the error in this case
      raise e unless e.message.include?('PG::UndefinedTable') ||
                     e.message.include?('does not exist') ||
                     e.is_a?(ActiveRecord::NoDatabaseError)
    end

    config.active_record.yaml_column_permitted_classes = [Date, BigDecimal]
  end

  def self.version
    @@ptime_version ||= build_version
  end

  def self.changelog_url
    # @@ptime_changelog_url ||= 'https://github.com/puzzle/puzzletime/blob/master/CHANGELOG.md'
    @@ptime_changelog_url ||= "https://github.com/puzzle/puzzletime/blob/#{commit_hash || 'master'}/CHANGELOG.md"
  end

  def self.build_version
    Puzzletime::VERSION
  end

  def self.commit_hash(short: false)
    return unless ENV['BUILD_COMMIT']

    commit = ENV['BUILD_COMMIT'].chomp
    return commit.first(8) if short

    commit
  end
end
