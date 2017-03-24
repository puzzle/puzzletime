# encoding: utf-8

class EmploymentRolesController < ManageController
  self.permitted_attrs = [:name, :billable, :level, :employment_role_category_id]

  def list_entries
    super.includes(:employment_role_category)
  end
end
