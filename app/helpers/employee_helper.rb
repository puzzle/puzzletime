module EmployeeHelper

  def multiple_check_box(object_name, field, value)
    object = instance_variable_get("@#{object_name}")
    check_box_tag "#{object_name}[#{field}][]", value, object.send(field).include?(value)
  end

end
