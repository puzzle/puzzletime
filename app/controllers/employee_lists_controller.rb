# encoding: utf-8

class EmployeeListsController < CrudController
  before_action :set_period

  before_render_show :set_employees
  before_render_form :set_current_employees

  def index
    @employee = @user
    super
  end

  private

  def list_entries
    super.where(employee_id: @user.id)
  end

  def set_employees
    @employees = @employee_list.employees.order(:lastname)
  end

  def set_current_employees
    @curr_employees = Employee.employed_ones(@period || Period.past_month)
  end

  def assign_attributes
    super
    entry.employee_id = @user.id
  end

  def model_params
    params.require(:employee_list).permit(:title, employee_ids: [])
  end
end
