#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module CompletableHelper
  def completed_icon(date)
    if recently_completed(date)
      picon('disk', class: 'green')
    else
      picon('square', class: 'red')
    end
  end

  def recently_completed(date)
    # logic should match Employee::pending_worktimes_commit
    date && date >= Time.zone.today.end_of_month - 1.month
  end

  def format_month(date)
    return unless date

    I18n.l(date, format: :month)
  end
end
