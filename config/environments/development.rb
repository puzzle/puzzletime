#  Copyright (c) 2006-2023, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded any time
  # it changes. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports.
  config.consider_all_requests_local = true

  # Enable server timing
  config.server_timing = true

  config.hosts = [
    "127.0.0.1",
    "localhost",
    ".local",
    ENV["RAILS_HOSTS"]
  ]

  # Enable/disable caching. By default caching is disabled.
  # Run rails dev:cache to toggle caching.
  # if Rails.root.join('tmp', 'caching-dev.txt').exist?
  #   config.action_controller.perform_caching = true
  #   config.action_controller.enable_fragment_cache_logging = true
  #
  #   config.cache_store = :memory_store
  #   config.public_file_server.headers = {
  #     'Cache-Control' => "public, max-age=#{2.days.to_i}"
  #   }
  # else
  #   config.action_controller.perform_caching = false
  #
  #   config.cache_store = :null_store
  # end

  # config.session_store(:cookie_store, key: '_app_session_dev')
  config.session_store(
    ActionDispatch::Session::CacheStore,
    expire_after: 12.hours,
    same_site: :lax,
    secure: false
  )

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = ENV.fetch('RAILS_STORAGE_SERVICE', 'local').to_sym

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  config.action_mailer.perform_caching = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise exceptions for disallowed deprecations.
  config.active_support.disallowed_deprecation = :raise

  # Tell Active Support which deprecation messages to disallow.
  config.active_support.disallowed_deprecation_warnings = []

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Highlight code that triggered database queries in logs.
  config.active_record.verbose_query_logs = true

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  # Suppress logger output for asset requests.
  config.assets.quiet = true

  # Raises error for missing translations.
  # config.i18n.raise_on_missing_translations = true

  # Annotate rendered view with file names.
  config.action_view.annotate_rendered_view_with_filenames = true

  # Use an evented file watcher to asynchronously detect changes in source code,
  # routes, locales, etc. This feature depends on the listen gem.
  config.file_watcher = ActiveSupport::EventedFileUpdateChecker

  # Uncomment if you wish to allow Action Cable access from any origin.
  # config.action_cable.disable_request_forgery_protection = true

  config.middleware.insert_before ActionDispatch::Cookies, Rack::RequestProfiler, printer: RubyProf::CallStackPrinter

  # Perform caching as the session is stored there
  config.action_controller.perform_caching = true

  # Mail sender
  config.action_mailer.delivery_method = (ENV['RAILS_MAIL_DELIVERY_METHOD'].presence || :smtp).to_sym

  if ENV['RAILS_MAIL_DELIVERY_CONFIG'].present?
    case config.action_mailer.delivery_method.to_s
    when 'smtp'
      config.action_mailer.smtp_settings =
        YAML.load("{ #{ENV['RAILS_MAIL_DELIVERY_CONFIG']} }").symbolize_keys
    when 'sendmail'
      config.action_mailer.sendmail_settings =
        YAML.load("{ #{ENV['RAILS_MAIL_DELIVERY_CONFIG']} }").symbolize_keys
    end
  else
    config.action_mailer.smtp_settings = { :address => '127.0.0.1', :port => 1025 }
  end

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true
  config.after_initialize do
    Bullet.enable = true
    Bullet.alert = true
    Bullet.bullet_logger = true
    Bullet.console = true
    Bullet.rails_logger = true
    Bullet.airbrake = false
    Bullet.add_footer = false
    Bullet.stacktrace_includes = []

    Bullet.add_safelist type: :unused_eager_loading, class_name: "Ordertime",      association: :employee
    Bullet.add_safelist type: :unused_eager_loading, class_name: "Ordertime",      association: :absence
    Bullet.add_safelist type: :unused_eager_loading, class_name: "Absencetime",    association: :work_item
    Bullet.add_safelist type: :unused_eager_loading, class_name: "Planning",       association: :work_item
    Bullet.add_safelist type: :unused_eager_loading, class_name: "Planning",       association: :employee
    Bullet.add_safelist type: :unused_eager_loading, class_name: "Order",          association: :contacts
    Bullet.add_safelist type: :unused_eager_loading, class_name: "Order",          association: :work_item
    Bullet.add_safelist type: :unused_eager_loading, class_name: "Order",          association: :kind
    Bullet.add_safelist type: :unused_eager_loading, class_name: "Order",          association: :department
    Bullet.add_safelist type: :unused_eager_loading, class_name: "Order",          association: :status
    Bullet.add_safelist type: :unused_eager_loading, class_name: "Order",          association: :responsible
    Bullet.add_safelist type: :unused_eager_loading, class_name: "Order",          association: :targets
    Bullet.add_safelist type: :unused_eager_loading, class_name: "Order",          association: :order_uncertainties
    Bullet.add_safelist type: :unused_eager_loading, class_name: "Expense",        association: :reviewer
    Bullet.add_safelist type: :n_plus_one_query,     class_name: "Order",          association: :order_team_members
    Bullet.add_safelist type: :n_plus_one_query,     class_name: "Order",          association: :team_members
    Bullet.add_safelist type: :n_plus_one_query,     class_name: "Order",          association: :order_contacts
    Bullet.add_safelist type: :n_plus_one_query,     class_name: "WorkItem",       association: :parent
    Bullet.add_safelist type: :n_plus_one_query,     class_name: "BillingAddress", association: :client
    Bullet.add_safelist type: :n_plus_one_query,     class_name: "BillingAddress", association: :contact
  end
end
