# encoding: utf-8

class EmploymentsController < ManageController

  self.nesting = Employee

  self.permitted_attrs = [
    :percent, :start_date, :end_date,
    :vacation_days_per_year, :comment,
    employment_roles_employments_attributes: [
      :id,
      :employment_role_id,
      :percent,
      :employment_role_level_id,
      :_destroy
    ]
  ]

  before_render_form :load_employment_roles
  before_render_form :load_employment_role_levels

  def list_entries
    super.includes(employment_roles_employments: [:employment_role,
                                                  :employment_role_level])
  end

  private

  def load_employment_roles
    @employment_roles = EmploymentRole.all
  end

  def load_employment_role_levels
    @employment_role_levels = EmploymentRoleLevel.all
  end
end
