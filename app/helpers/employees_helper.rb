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

  def format_current_employment_roles(employee, separator = ', ')
    employment = employee.current_employment
    safe_join(employment.employment_roles_employments.map do |ere|
      [ere.employment_role.name,
       ere.employment_role_level.present? ? ere.employment_role_level.name : nil,
       format_percent(ere.percent)].compact.join(' ')
    end, separator)
  end

  def version_author(version)
    if version.version_author.present?
      employee = Employee.where(id: version.version_author).first
      employee.to_s if employee.present?
    end
  end

  def version_changes(version)
    item_class = version.item_type.constantize
    safe_join(version.changeset) do |attr, (from, to)|
      unless from.blank? && to.blank?
        content_tag(:div, version_attribute_change(item_class, attr, from, to))
      end
    end
  end

  def version_attribute_change(item_class, attr, from, to)
    key = version_attribute_change_key(from, to)
    t("version.attribute_change.#{key}", version_attribute_change_args(item_class, attr, from, to))
  end

  def version_attribute_change_key(from, to)
    if from.present? && to.present?
      'from_to'
    elsif from.present?
      'from'
    elsif to.present?
      'to'
    end
  end

  def version_attribute_change_args(item_class, attr, from, to)
    { attr: item_class.human_attribute_name(attr),
      from: f(from),
      to: f(to) }
  end
end
