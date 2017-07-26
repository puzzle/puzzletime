# encoding: utf-8

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


module EmploymentsHelper
  def format_employment_percent(employment)
    p = employment.percent
    "#{p == p.to_i ? p.to_i : p} %"
  end
end
