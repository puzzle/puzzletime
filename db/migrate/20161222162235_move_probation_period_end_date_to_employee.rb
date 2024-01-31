#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

class MoveProbationPeriodEndDateToEmployee < ActiveRecord::Migration[5.1]
  def change
    add_column :employees, :probation_period_end_date, :date

    Employment.where.not(probation_period_end_date: nil).includes(:employee).find_each do |e|
      e.employee.update_column(:probation_period_end_date, e.probation_period_end_date)
    end

    remove_column :employments, :probation_period_end_date
  end
end
