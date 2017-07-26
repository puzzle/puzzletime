# encoding: utf-8

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


class WorktimeEdit < Splitable
  self.incomplete_finish = false

  def add_worktime(worktime)
    if worktime.hours - remaining_hours > 0.00001 # we are working with floats: use delta
      worktime.errors.add(:hours, 'Die gesamte Anzahl Stunden kann nicht vergrössert werden')
    end
    worktime.employee = original.employee
    super(worktime) if worktime.errors.empty?
    worktime.errors.empty?
  end

  def page_title
    "Arbeitszeit von #{original.employee.label} bearbeiten"
  end

  def build_worktime
    empty? ? Ordertime.find(original_id) : Ordertime.new
  end
end
