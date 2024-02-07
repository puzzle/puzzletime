# frozen_string_literal: true

#  Copyright (c) 2006-2019, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

if ENV['SENTRY_DSN']
  require 'sentry-raven'
  Raven.configure do |config|
    config.sanitize_fields = Rails.application.config.filter_parameters.map(&:to_s)
    config.tags[:version] = Puzzletime.version

    if (commit = ENV.fetch('OPENSHIFT_BUILD_COMMIT', nil))
      config.tags[:commit] = commit
      config.release = "#{Puzzletime.version}_#{commit}"
    else
      config.release = Puzzletime.version
    end

    if (project = ENV.fetch('OPENSHIFT_BUILD_NAMESPACE', nil))
      config.tags[:project] = project
      config.tags[:customer] = project.split('-')[0]
    end
  end
end
