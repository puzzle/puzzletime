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

    ErrorTracker.report_exception(error, payload)
  end

  # Called once by active job before perform_now, after delayed job callbacks
  def deserialize(job_data)
    super
    ErrorTracker.set_extras(active_job: job_data)
  end
end
