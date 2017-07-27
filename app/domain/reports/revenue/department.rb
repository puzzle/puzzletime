#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


module Reports::Revenue
  class Department < Base

    self.grouping_model = ::Department
    self.grouping_fk = :department_id

  end
end
