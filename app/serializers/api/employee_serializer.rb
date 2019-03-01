#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


module Api
  class EmployeeSerializer
    include FastJsonapi::ObjectSerializer

    has_one :current_employment, record_type: :employment, serializer: :employment do |employee|
      employee.current_employment
    end

  end
end