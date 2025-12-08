# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'error_tracker'

if ErrorTracker.airbrake_like?
  require 'airbrake'

  Airbrake.configure do |config|
    config.environment = Rails.env
    config.ignore_environments = %i[development test]
    # if no host is given, ignore all environments
    config.ignore_environments << :production if Settings.error_tracker.airbrake.host.blank?

    config.project_id     = 1 # required, but any positive integer works
    config.project_key    = Settings.error_tracker.airbrake.api_key
    config.host           = Settings.error_tracker.airbrake.host
    config.blacklist_keys << 'pwd'
    config.blacklist_keys << 'RAILS_DB_PASSWORD'
    config.blacklist_keys << 'RAILS_AIRBRAKE_API_KEY'
    config.blacklist_keys << 'RAILS_SECRET_TOKEN'
    config.blacklist_keys << 'RAILS_SECRET_KEY_BASE'
    config.blacklist_keys << 'RAILS_HIGHRISE_TOKEN'
    config.blacklist_keys << 'RAILS_SMALL_INVOICE_TOKEN'
  end

  ignored_exceptions = %w[ActionController::MethodNotAllowed
                          ActionController::RoutingError
                          ActionController::InvalidAuthenticityToken
                          ActionController::UnknownHttpMethod]

  Airbrake.add_filter do |notice|
    notice.ignore! if notice[:errors].pluck(:type).intersect?(ignored_exceptions)
  end
end
