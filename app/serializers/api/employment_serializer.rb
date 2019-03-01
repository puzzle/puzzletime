#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


module Api
  class EmploymentSerializer
    include FastJsonapi::ObjectSerializer

    has_many :employment_roles, record_type: :employment_role do |employment|
      employment.employment_roles_employments
    end
  end
end