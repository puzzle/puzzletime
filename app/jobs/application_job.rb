# frozen_string_literal: true

#  Copyright (c) 2006-2019, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

class ApplicationJob < ActiveJob::Base
  rescue_from(Exception) do |error|
    payload = { cgi_data: ENV.to_hash }
    payload[:code] = error.code if error.respond_to?(:code)
    payload[:data] = error.data if error.respond_to?(:data)
    Airbrake.notify(error, payload) if airbrake?
    Sentry.capture_exception(error, extra: payload) if sentry?
  end

  # Called once by active job before perform_now, after delayed job callbacks
  def deserialize(job_data)
    super
    init_sentry_job_context(job_data) if sentry?
  end

  def airbrake?
    ENV['RAILS_AIRBRAKE_HOST'].present?
  end

  def sentry?
    ENV['GLITCHTIP_DSN'].present?
  end

  def init_sentry_job_context(job_data)
    Sentry.set_extras(active_job: job_data)
  end
end
