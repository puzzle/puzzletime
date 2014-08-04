# encoding: utf-8

class PlanningsController < CrudController

  before_action :set_period

  before_render_form :build_planning_form

  def index
    redirect_to action: 'my_planning'
  end

  def my_planning
    @employee = @user
    @graph = EmployeePlanningGraph.new(@employee, @period)
    render template: 'plannings/employee_planning'
  end

  def my_projects
    @projects = @user.managed_projects.includes(:department)
    render template: 'plannings/projects'
  end

  def existing
    if params[:planning][:start_week_date].present?
      current_week = Week.from_string(params[:planning][:start_week_date])
      @period = extended_period(current_week.to_date) if current_week.valid?
    end
    set_employee
    @graph = EmployeePlanningGraph.new(@employee, @period)
  end

  def employees
    set_employees
  end

  def employee_planning
    set_employee
    if params[:week_date].present?
      @period = extended_period(Date.parse(params[:week_date]))
    # else: use default period
    end
    @graph = EmployeePlanningGraph.new(@employee, @period)
  end

  def employee_lists_planning
    @employee_list = EmployeeList.find_by_id(params[:employee_list_id])
    @employee_list_name = @employee_list.title
    period = @period.present? ? @period : Period.current_month
    @graph = EmployeesPlanningGraph.new(@employee_list.employees.includes(:employments).list, period)
  end

  def projects
    @projects = WorkItem.list
  end

  def project_planning
    unless params[:work_item_id]
      return redirect_to(action: 'projects')
    end
    @project = WorkItem.find(params[:work_item_id])
    @graph = ProjectPlanningGraph.new(@project, @period)
  end

  def departments
    @departments = Department.list
  end

  def department_planning
    unless params[:department_id]
      return redirect_to(action: 'departments')
    end
    @department = Department.find(params[:department_id])

    employees = planned_employees(@department, @perdiod)
    @graph = EmployeesPlanningGraph.new(employees, @period)
  end

  def company_planning
    period = @period.present? ? @period : Period.current_month
    @graph = EmployeesPlanningGraph.new(Employee.employed_ones(period).includes(:employments).list, period)
  end

  def new
    set_employee
    @employee ||= @user
    entry.employee = @employee
    entry.project = Project.find(params[:project_id]) if params[:project_id]
    entry.start_week = Week.from_string(params[:date]).to_integer if params[:date]
    super
  end


  private

  def index_url
    { action: 'employee_planning', employee_id: entry.employee_id }
  end

  def build_planning_form
    @employee = entry.employee
    set_employees
    @projects = WorkItem.list
    @graph = EmployeePlanningGraph.new(@employee, @period)
    @period = extended_period(entry.start_week_date)
  end

  def set_employee
    id = params[:employee_id].presence ||
         (params[:planning] && params[:planning][:employee_id].presence)
    @employee = Employee.find(id) if id
  end

  def set_employees
    unless @period
      @period = Period.current_month
    end
    @employees = Employee.employed_ones(@period)
  end

  def extended_period(date)
    date ||= Date.today
    Period.new(date - 14, date + 21)
  end

  def planned_employees(department, period)
    employees = Employee.where(department_id: department).includes(:employments).list
    period ||= Period.current_month
    employees.select do |e|
      e.employment_at(period.startDate).present? ||
      e.employment_at(period.endDate).present?
    end
  end

  def assign_attributes
    planning_params = params[:planning]
    entry.employee = Employee.find(planning_params[:employee_id]) if planning_params[:employee_id].present?
    entry.work_item = WorkItem.find(planning_params[:work_item_id]) if planning_params[:work_item_id].present?
    entry.start_week = Week.from_string(planning_params[:start_week_date]).to_integer if planning_params[:start_week_date].present?
    entry.definitive = planning_params[:type] == 'definitive'
    entry.is_abstract = planning_params[:abstract_concrete] == 'abstract'
    entry.abstract_amount = (planning_params[:abstract_amount].blank? ? 0 : planning_params[:abstract_amount])
    case planning_params[:repeat_type]
      when 'no'
        entry.end_week = entry.start_week
      when 'until'
        entry.end_week = Week.from_string(planning_params[:end_week_date]).to_integer if planning_params[:end_week_date].present?
      when 'forever'
        entry.end_week = nil
    end
    entry.monday_am = boolean_param(planning_params[:monday_am])
    entry.monday_pm = boolean_param(planning_params[:monday_pm])
    entry.tuesday_am = boolean_param(planning_params[:tuesday_am])
    entry.tuesday_pm = boolean_param(planning_params[:tuesday_pm])
    entry.wednesday_am = boolean_param(planning_params[:wednesday_am])
    entry.wednesday_pm = boolean_param(planning_params[:wednesday_pm])
    entry.thursday_am = boolean_param(planning_params[:thursday_am])
    entry.thursday_pm = boolean_param(planning_params[:thursday_pm])
    entry.friday_am = boolean_param(planning_params[:friday_am])
    entry.friday_pm = boolean_param(planning_params[:friday_pm])
    entry.description = planning_params[:description]
  end

  def boolean_param(param)
    param.present? ? param : false
  end

end
