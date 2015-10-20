# encoding: utf-8

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
    object = instance_variable_get("@#{object_name}")
    check_box_tag "#{object_name}[#{field}][]", value, object.send(field).include?(value)
  end
end
