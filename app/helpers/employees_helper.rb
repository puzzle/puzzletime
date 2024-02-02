# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module EmployeesHelper
  def format_employee_current_percent(employee)
    value = employee.current_percent
    case value
    when nil then 'keine'
    when value.to_i then "#{value.to_i} %"
    else "#{value} %"
    end
  end

  def multiple_check_box(object_name, field, value)
    object = instance_variable_get(:"@#{object_name}")
    check_box_tag "#{object_name}[#{field}][]", value, object.send(field).include?(value)
  end

  def format_current_employment_roles(employee, separator = ', ')
    employment = employee.current_employment
    return if employment.nil?

    safe_join(employment.employment_roles_employments.map do |ere|
      [ere.employment_role.name,
       ere.employment_role_level.present? ? ere.employment_role_level.name : nil,
       format_percent(ere.percent)].compact.join(' ')
    end, separator)
  end
end
