# encoding: utf-8

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true

  # Perform caching as the session is stored there
  config.action_controller.perform_caching = true

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  config.action_mailer.perform_caching = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  config.middleware.insert_before ActionDispatch::Cookies, Rack::RequestProfiler, printer: RubyProf::CallStackPrinter

  # Use an evented file watcher to asynchronously detect changes in source code,
  # routes, locales, etc. This feature depends on the listen gem.
  # config.file_watcher = ActiveSupport::EventedFileUpdateChecker

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

    Bullet.add_whitelist type: :unused_eager_loading, class_name: "Ordertime", association: :employee
    Bullet.add_whitelist type: :unused_eager_loading, class_name: "Ordertime", association: :absence
    Bullet.add_whitelist type: :unused_eager_loading, class_name: "Absencetime", association: :work_item
    Bullet.add_whitelist type: :unused_eager_loading, class_name: "Planning", association: :work_item
    Bullet.add_whitelist type: :unused_eager_loading, class_name: "Planning", association: :employee
    Bullet.add_whitelist type: :unused_eager_loading, class_name: "Order", association: :contacts
    Bullet.add_whitelist type: :unused_eager_loading, class_name: "Order", association: :work_item
    Bullet.add_whitelist type: :unused_eager_loading, class_name: "Order", association: :kind
    Bullet.add_whitelist type: :unused_eager_loading, class_name: "Order", association: :department
    Bullet.add_whitelist type: :unused_eager_loading, class_name: "Order", association: :status
    Bullet.add_whitelist type: :unused_eager_loading, class_name: "Order", association: :responsible
    Bullet.add_whitelist type: :unused_eager_loading, class_name: "Order", association: :targets

    Bullet.add_whitelist type: :n_plus_one_query, class_name: "Order", association: :order_team_members
    Bullet.add_whitelist type: :n_plus_one_query, class_name: "Order", association: :team_members
    Bullet.add_whitelist type: :n_plus_one_query, class_name: "Order", association: :order_contacts
    Bullet.add_whitelist type: :n_plus_one_query, class_name: "WorkItem", association: :parent
    Bullet.add_whitelist type: :n_plus_one_query, class_name: "BillingAddress", association: :client
    Bullet.add_whitelist type: :n_plus_one_query, class_name: "BillingAddress", association: :contact
  end
end
