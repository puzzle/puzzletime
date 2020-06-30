#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

WorkingCondition.seed_once(
  :valid_from,
  { valid_from: nil,
    must_hours_per_day: 8,
    vacation_days_per_year: 25 }
)
