#  Copyright (c) 2006-2019, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

class ApplicationJob < ActiveJob::Base
  rescue_from(Exception) do |e|
    payload = { cgi_data: ENV.to_hash }
    payload[:code] = e.code if e.respond_to?(:code)
    payload[:data] = e.data if e.respond_to?(:data)
    Airbrake.notify(e, payload) if airbrake?
    Raven.capture_exception(error, extra: parameters) if sentry?
  end

  def airbrake?
    ENV['RAILS_AIRBRAKE_HOST'].present?
  end

  def sentry?
    ENV['SENTRY_DSN'].present?
  end
end
