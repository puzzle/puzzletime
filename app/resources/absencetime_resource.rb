# frozen_string_literal: true

#  Copyright (c) 2006-2026, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# Mirrors AbsencetimesController; see WorktimeResource for the rules shared with ordertimes. Management may book and
# delete (mailing the employee) but, per Ability, not update other employees' absences.
class AbsencetimeResource < WorktimeResource
  model Absencetime
  secondary_endpoint '/absencetimes/multi', %i[multi]

  attribute :absence_id, :integer
  attribute :billable, :boolean, writable: false
end
