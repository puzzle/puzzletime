# frozen_string_literal: true

#  Copyright (c) 2006-2019, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'error_tracker'

if ErrorTracker.sentry_like?
  Sentry.init do |config|
    config.dsn = Settings.error_tracker.sentry.dsn

    # Additionally exclude the following exceptions:
    # config.excluded_exceptions += []

    # do not send list of gem dependencies
    config.send_modules = false

    # Whether to capture local variables from the raised exceptions frame.
    config.include_local_variables = true

    config.breadcrumbs_logger = %i[active_support_logger http_logger]

    # Sentry automatically sets the current environment from the environment variables:
    # SENTRY_CURRENT_ENV, SENTRY_ENVIRONMENT, RAILS_ENV, RACK_ENV in that order and
    # defaults to development
    # config.environment = Rails.env

    config.release = Settings.puzzletime.run.full_versioon

    filter = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)

    config.before_send = lambda do |event, _hint|
      event.extra = filter.filter(event.extra) if event.extra
      event.user = filter.filter(event.user) if event.user
      event.contexts = filter.filter(event.contexts) if event.contexts

      # Add transaction name because it's not displayed otherwise in glitchtip
      event.tags[:transaction] ||= event.transaction if event.transaction

      event
    end
  end
end
