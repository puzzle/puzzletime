#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


Airbrake.configure do |config|
  config.environment = Rails.env
  config.ignore_environments = [:development, :test]
  # if no host is given, ignore all environments
  config.ignore_environments << :production if ENV['RAILS_AIRBRAKE_HOST'].blank?

  config.project_id     = 1 # required, but any positive integer works
  config.project_key    = ENV['RAILS_AIRBRAKE_API_KEY']
  config.host           = ENV['RAILS_AIRBRAKE_HOST']
  config.blacklist_keys << 'RAILS_DB_PASSWORD'
  config.blacklist_keys << 'RAILS_AIRBRAKE_API_KEY'
  config.blacklist_keys << 'RAILS_SECRET_TOKEN'
  config.blacklist_keys << 'RAILS_HIGHRISE_TOKEN'
  config.blacklist_keys << 'RAILS_SMALL_INVOICE_TOKEN'
end

ignored_exceptions = %w(ActionController::MethodNotAllowed
                        ActionController::RoutingError
                        ActionController::UnknownHttpMethod)

Airbrake.add_filter do |notice|
  if (notice[:errors].map { |e| e[:type] } & ignored_exceptions).present?
    notice.ignore!
  end
end
