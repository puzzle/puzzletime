#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


module Api
  module V1
    class EmployeeSerializer
      include FastJsonapi::ObjectSerializer

      attributes :shortname, :firstname, :lastname, :email, :marital_status, :nationalities, :graduation

      attribute :department_shortname do |employee|
        employee.department&.shortname
      end

      attribute :employment_roles do |employee|
        Array.wrap(employee.current_employment&.employment_roles_employments).map do |employment_roles_employment|
          {
            name: employment_roles_employment.employment_role.name,
            percent: employment_roles_employment.percent.to_f
          }
        end
      end
    end
  end
end