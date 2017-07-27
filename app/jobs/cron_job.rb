#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


class CronJob < BaseJob
  class_attribute :cron_expression

  # Enqueue delayed job if it is not enqueued already
  def schedule
    enqueue!(cron: cron_expression) unless scheduled?
  end

  # Is this job enqueued in delayed job?
  def scheduled?
    delayed_jobs.present?
  end
end
