# encoding: utf-8

class PlanningsController < CrudController
  before_action :set_period

  before_render_form :build_planning_form

  def index
    redirect_to action: 'my_planning'
  end

  def redesign;end

  def my_planning
    @employee = @user
    @graph = EmployeePlanningGraph.new(@employee, @period)
    render template: 'plannings/employee_planning'
  end

  def my_work_items
    @work_items = WorkItem
      .recordable
      .joins(:accounting_post)
      .joins('LEFT JOIN orders ON ' \
             'orders.work_item_id = ANY (work_items.path_ids)')
      .where(orders: { responsible_id: current_user.id })
      .list

    render template: 'plannings/work_items'
  end

  def existing
    if params[:planning][:start_week_date].present?
      current_week = Week.from_string(params[:planning][:start_week_date])
      @period = extended_period(current_week.to_date) if current_week.valid?
    end
    set_employee
    @graph = EmployeePlanningGraph.new(@employee, @period) if @employee
  end

  def employees
    set_employees
  end

  def employee_planning
    set_employee
    if params[:week_date].present?
      @period = extended_period(Date.parse(params[:week_date]))
    end
    @graph = EmployeePlanningGraph.new(@employee, @period)
  end

  def employee_lists_planning
    @employee_list = EmployeeList.find_by_id(params[:employee_list_id])
    if @employee_list
      @employee_list_name = @employee_list.try :title
      period = @period.present? ? @period : Period.next_three_months
      employees = @employee_list.employees.includes(:employments).list
      @graph = EmployeesPlanningGraph.new(employees, period)
    else
      flash[:alert] = 'Liste nicht gefunden'
      redirect_to controller: 'employee_lists', action: 'index'
    end
  end

  def work_items
    @work_items = WorkItem.recordable.joins(:accounting_post).list
  end

  def work_item_planning
    unless params[:work_item_id]
      return redirect_to(action: 'work_items')
    end
    @work_item = WorkItem.find(params[:work_item_id])
    @graph = WorkItemPlanningGraph.new(@work_item, @period)
  end

  def departments
    @departments = Department.list
  end

  def department_planning
    unless params[:department_id]
      return redirect_to(action: 'departments')
    end
    @department = Department.find(params[:department_id])

    employees = planned_employees(@department, @period)
    @graph = EmployeesPlanningGraph.new(employees, @period)
  end

  def company_planning
    period = @period.present? ? @period : Period.next_three_months
    employees = Employee.employed_ones(period).includes(:employments).list
    @graph = EmployeesPlanningGraph.new(employees, period, true)
  end

  def new
    set_employee
    @employee ||= @user
    entry.employee = @employee
    entry.work_item = WorkItem.find(params[:work_item_id]) if params[:work_item_id]
    entry.start_week = Week.from_string(params[:date]).to_integer if params[:date]
    super
  end

  private

  def index_path
    { action: 'employee_planning', employee_id: entry.employee_id }
  end

  def build_planning_form
    @employee = entry.employee
    set_employees
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
      @period = Period.next_three_months
    end
    @employees = Employee.employed_ones(@period)
  end

  def extended_period(date)
    date ||= Time.zone.today
    Period.new(date - 14, date + 21)
  end

  def planned_employees(department, period)
    employees = Employee.where(department_id: department).includes(:employments).list
    period ||= Period.next_three_months
    employees.select do |e|
      e.employment_at(period.start_date).present? ||
          e.employment_at(period.end_date).present?
    end
  end

  def assign_attributes # rubocop:disable Metrics/AbcSize
    p = params[:planning]
    entry.employee = Employee.find(p[:employee_id]) if p[:employee_id].present?
    entry.work_item = WorkItem.find(p[:work_item_id]) if p[:work_item_id].present?
    if p[:start_week_date].present?
      entry.start_week = Week.from_string(p[:start_week_date]).to_integer
    end
    entry.definitive = p[:type] == 'definitive'
    entry.is_abstract = p[:abstract_concrete] == 'abstract'
    entry.abstract_amount = p[:abstract_amount].blank? ? 0 : p[:abstract_amount]
    entry.end_week = end_of_week_param(p)
    assign_week_day_params(p)
    entry.description = p[:description]
  end

  def end_of_week_param(p)
    case p[:repeat_type]
    when 'no'
      entry.start_week
    when 'until'
      if p[:end_week_date].present?
        Week.from_string(p[:end_week_date]).to_integer
      end
    when 'forever'
      nil
    end
  end

  def assign_week_day_params(p)
    %w(monday tuesday wednesday thursday friday).each do |day|
      %w(am pm).each do |part|
        attr = "#{day}_#{part}"
        entry.send("#{attr}=", boolean_param(p[attr]))
      end
    end
  end

  def boolean_param(param)
    param.present? ? param : false
  end
end
