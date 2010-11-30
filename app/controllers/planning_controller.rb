class PlanningController < ApplicationController
  
  before_filter :authenticate
  
  before_filter :setPeriod
  
  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :delete ], :redirect_to => { :action => 'index' }
  verify :method => :post, :only => [ :create ], :redirect_to => { :action => 'add' }   
  verify :method => :post, :only => [ :update ], :redirect_to => { :action => 'edit' }     
  
  def index 
    redirect_to :action => 'my_planning'
  end
  
  def my_planning
    @employee = @user
    @graph = EmployeePlanningGraph.new(@employee, @period)
    render :template => 'planning/employee_planning'
  end
  
  def my_projects
    @projects = @user.managed_projects
    render :template => 'planning/projects'
  end
  
  def existing
    if params[:start_week_date].present?
      current_week = Week::from_string(params[:start_week_date]).to_date
      @period = extended_period(current_week)
    # else: use default period
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
  
  def employee_lists
    @employee = @user
    @employee_lists = EmployeeList.find(:all, :conditions => { :employee_id => @employee.id })
  end
  
  def employee_lists_planning
    @employee_list = EmployeeList.find_by_id(params[:employee_list_id])
    @employee_list_name = @employee_list.title
    @employee_list_items = @employee_list.employee_list_items
    
    # select only the affected employees
    elis = @employee_list.employee_list_items
    @employees = Employee.find(elis.collect{|e| e.employee_id})
    
    period = @period.present? ? @period : Period.currentMonth
    @graph = EmployeesPlanningGraph.new(@employees, period)
  end
  
  def projects
    @projects = Project.top_projects
  end
  
  def project_planning
    unless params[:project_id]
      return redirect_to(:action => 'projects')
    end
    @project = Project.find(params[:project_id])
    @graph = ProjectPlanningGraph.new(@project, @period)
  end
  
  def departments
    @departmens = Department.list
  end

  def department_planning
    unless params[:department_id]
      return redirect_to(:action => 'departments')
    end
    @department = Department.find(params[:department_id])

    employees = planned_employees(@department, @perdiod)
    @graph = EmployeesPlanningGraph.new(employees, @period)
  end

  def company_planning
    period = @period.present? ? @period : Period.currentMonth
    @graph = EmployeesPlanningGraph.new(Employee.employed_ones(period), period)
  end
    
  def add
    set_employee
    @employee ||= @user
    @planning = Planning.new(:employee => @employee)
    if params[:project_id]
      @planning.project = Project.find(params[:project_id])
    end
    if params[:date]
      week_date = Week::from_string(params[:date])
      @planning.start_week = week_date.to_integer
      @period = extended_period(week_date.to_date)
    else
      @period = extended_period
    end
    build_planning_form
  end
  
  def create
    set_employees
    @planning = Planning.new
    set_planning_attributes(params[:planning])
    if @planning.save
      flash[:notice] = "Die Planung wurde erfolgreich erfasst"      
      redirect_to :action => 'employee_planning', :employee_id => @planning.employee
    else
      @employee = @planning.employee
      build_planning_form
      render :action => 'add'
    end
  end
  
  def edit
    @planning = Planning.find(params[:id])
    @employee = @planning.employee
    start_date = Week::from_integer(@planning.start_week).to_date
    @period = extended_period(start_date)
    build_planning_form
  end
  
  def update
    @planning = Planning.find(params[:id])
    set_planning_attributes(params[:planning])
    @employee = @planning.employee
    if @planning.save
      flash[:notice] = "Die Planung wurde erfolgreich erfasst"      
      redirect_to :action => 'employee_planning', :employee_id => @employee
    else
      build_planning_form
      render :action => 'edit'
    end
  end
  
  def delete
    planning = Planning.find(params[:planning])
    if planning.destroy
      flash[:notice] = "Die Planung wurde entfernt "
    else
      flash[:error] = "Die Planung konnte nicht geloescht werden"
    end
    redirect_to :action => 'employee_planning', :employee_id => planning.employee
  end

private
  def build_planning_form
    set_employees
    @projects = Project.top_projects 
    @graph = EmployeePlanningGraph.new(@employee, @period)    
  end
  
  def set_employee
    @employee = Employee.find(params[:employee_id]) if params[:employee_id].present?
  end
  
  def set_employees
    unless @period
      @period = Period.currentMonth
    end
    @employees = Employee.employed_ones(@period)
  end

  def extended_period(date = Date.today)
    Period.new(date - 14, date + 21)
  end
  
  def planned_employees(department, period)
    #this could be improved with a many-to-many table relation between Department and Employee
    projects = Project.all(:conditions => {:department_id => department})
    memberships = Projectmembership.all(:conditions => {:project_id => projects.collect{|p|p.id}, :active => true})
    employees = Employee.find(memberships.collect{|m| m.employee_id})
    period ||= Period.currentMonth
    employees.select{|e| e.employment_at(period.startDate).present? || e.employment_at(period.endDate).present?}
  end
  
  def set_planning_attributes(planning_params)
    @planning.employee = Employee.find(planning_params[:employee_id]) if planning_params[:employee_id]
    @planning.project = Project.find(planning_params[:project_id]) if planning_params[:project_id]
    @planning.start_week = Week::from_string(planning_params[:start_week_date]).to_integer if planning_params[:start_week_date] 
    @planning.definitive = planning_params[:type] == 'definitive'
    case planning_params[:repeat_type]
      when 'no'
        @planning.end_week = @planning.start_week
      when 'until'
        @planning.end_week = Week::from_string(planning_params[:end_week_date]).to_integer if planning_params[:end_week_date]
      when 'forever'
        @planning.end_week = nil
    end
    @planning.monday_am = boolean_param(planning_params[:monday_am])
    @planning.monday_pm = boolean_param(planning_params[:monday_pm])
    @planning.tuesday_am = boolean_param(planning_params[:tuesday_am])
    @planning.tuesday_pm = boolean_param(planning_params[:tuesday_pm])
    @planning.wednesday_am = boolean_param(planning_params[:wednesday_am])
    @planning.wednesday_pm = boolean_param(planning_params[:wednesday_pm])
    @planning.thursday_am = boolean_param(planning_params[:thursday_am])
    @planning.thursday_pm = boolean_param(planning_params[:thursday_pm])
    @planning.friday_am = boolean_param(planning_params[:friday_am])
    @planning.friday_pm = boolean_param(planning_params[:friday_pm])
    @planning.description = planning_params[:description]
  end
  
  def boolean_param(param)
    param.present? ? param : false
  end
  
end