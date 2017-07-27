#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


class OvertimeVacationsController < ManageController
  self.nesting = Employee

  self.permitted_attrs = [:hours, :transfer_date]

  def show
    redirect_to employee_overtime_vacations_path(entry.employee)
  end
end
