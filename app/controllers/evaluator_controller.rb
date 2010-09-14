
require 'fastercsv'

class EvaluatorController < ApplicationController
 
  # Checks if employee came from login or from direct url.
  before_filter :authenticate
  before_filter :authorize, :only => [:clients, :employees, :overtime,
                                      :clientProjects, :employeeProjects, :employeeAbsences,
                                      :exportCapacityCSV, :exportExtendedCapacityCSV, :exportMAOverview]
  before_filter :setPeriod
  
  helper_method :user_view?
  
  verify :method => :post, 
         :only => [ :completeProject, :complete_all, :book_all ],
         :redirect_to => { :action => :userProjects }
  
  def index
    overview
  end
  
  def overview
    setEvaluation
    setNavigationLevels
    @notifications = UserNotification.list_during(@period)
    render :action => (user_view? ? 'userOverview' : 'overview' )
  end
  
  def details  
    redirect_to :action => 'absencedetails' if params[:evaluation] == 'absencedetails'
    setEvaluation
    setNavigationLevels
    setEvaluationDetails
    paginateTimes                          
  end
  
  def attendanceDetails
    setEvaluation
    setNavigationLevels
    @evaluation = AttendanceEval.new(params[:category_id] || @user.id)
    setEvaluationDetails
    paginateTimes    
    render :action => 'details' 
  end

  def absencedetails
    session[:evalLevels] = Array.new
    params[:evaluation] = 'absencedetails'
    setEvaluation
    @period ||= Period.comingMonth Date.today, 'Kommender Monat'
    @notifications = UserNotification.list_during(@period)
    paginateTimes
  end
  
  def weekly
    redirect_to :controller => 'graph', :action => 'weekly'
  end
  
  def all_absences
    redirect_to :controller => 'graph', :action => 'all_absences'
  end
  
  def employee_planning
    redirect_to :controller => 'planning', :action => 'employee_planning', :employee_id => params[:category_id]
  end
  
  def employees_planning
    redirect_to :controller => 'planning', :action => 'employees_planning'
  end

  def my_planning
    redirect_to :controller => 'planning', :action => 'my_planning'
  end
  
  def project_planning
    redirect_to :controller => 'planning', :action => 'project_planning'
  end
  
  def department_planning
    redirect_to :controller => 'planning', :action => 'department_planning', :department_id => params[:category_id]
  end
  
  def company_planning
    redirect_to :controller => 'planning', :action => 'company_planning'
  end
  
  
  ########################  DETAIL ACTIONS  #########################
  
  def compose_report
    setEvaluation
    setEvaluationDetails
  end
  
  def report
    setEvaluation
    setEvaluationDetails
    options = params[:only_billable] ? { :conditions => [ "worktimes.billable = 't'" ] } : {}
    @times = @evaluation.times(@period, options)
    combine_times if params[:combine]
    render :layout => false
  end
  
  def exportCSV
    setEvaluation
    setEvaluationDetails
    filename = "puzzletime_" + csvLabel(@evaluation.category) + "-" +
               csvLabel(@evaluation.division) + ".csv"
    setExportHeader(filename)
    send_data(@evaluation.csvString(@period),
              :type => 'text/csv; charset=utf-8; header=present',
              :filename => filename)  
  end
  
  def book_all
    setEvaluation
    setEvaluationDetails
    @evaluation.times(@period).each do |worktime|
      #worktime cannot be directly updated because it's loaded with :joins
      Worktime.update worktime.id, :booked => 1   
    end
    flash[:notice] = "Alle Arbeitszeiten "
    flash[:notice] += "von #{Employee.find(@evaluation.employee_id).label} " if @evaluation.employee_id
    flash[:notice] += "f&uuml;r #{Project.find(@evaluation.account_id).label_verbose}" +
                     "#{ ' w&auml;hrend dem ' + @period.to_s if @period} wurden verbucht."
    redirect_to params.merge({:action => 'details'})
  end
    
  ######################  OVERVIEW ACTIONS  #####################3

  def completeProject
    project = Project.find params[:project_id]
    memberships = @user.projectmemberships.find(:first, 
            :conditions => ["project_id = ?", params[:project_id]])
    if memberships.nil?
      # no direct membership - complete parent project
      memberships = @user.projectmemberships.find(:all,
            :conditions => ["? = ANY (projects.path_ids)", params[:project_id]])
    else
      memberships = [memberships] 
    end
    memberships.each do |pm|
      pm.update_attributes(:last_completed => Date.today)
    end
    flash[:notice] = "Das Datum der kompletten Erfassung aller Zeiten " +
                     "f&uuml;r das Projekt #{project.label_verbose} wurde aktualisiert."
    redirectToOverview
  end
  
  def complete_all
    @user.projectmemberships.find(:all, :conditions => ['active']).each do |pm|
       pm.update_attributes(:last_completed => Date.today)
    end
    flash[:notice] = "Das Datum der kompletten Erfassung aller Zeiten wurde f&uuml;r alle Projekte aktualisiert."
    redirectToOverview
  end
  
  def exportCapacityCSV
    if @period
      sendCSV(CapacityReport.new(@period))
    else
      flash[:notice] = "Bitte wählen Sie eine Zeitspanne für die detaillierte Auslastung."
      redirect_to :back
    end
  end
  
  def exportExtendedCapacityCSV
    if @period
      sendCSV(ExtendedCapacityReport.new(@period))
    else
      flash[:notice] = "Bitte wählen Sie eine Zeitspanne für die Auslastung."
      redirect_to :back
    end
  end
  
  def exportMAOverview
    @period ||= Period.currentYear
    #render :action => :exportMAOverview, :layout => false
  end
  
  ########################  PERIOD ACTIONS  #########################
  
  def selectPeriod
    @period = Period.new() if @period.nil?
  end
  
  def currentPeriod
    session[:period] = nil
    redirectToOverview
  end
  
  def changePeriod
    if params[:shortcut]
      @period = Period.parse(params[:shortcut])
    else
      @period = Period.retrieve(params[:period][:startDate], 
                                params[:period][:endDate],
                                params[:period][:label])  
    end
    raise ArgumentError, "Start Datum nach End Datum" if @period.negative?   
    session[:period] = [@period.startDate.to_s, @period.endDate.to_s,  @period.label]  
    redirectToOverview             
  rescue ArgumentError => ex        # ArgumentError from Period.new or if period.negative?
    flash[:notice] = "Ung&uuml;ltige Zeitspanne: " + ex
    render :action => 'selectPeriod'    
  end
  
  
  # Dispatches evaluation names used as actions
  def method_missing(action, *args)
    params[:evaluation] = action.to_s
    overview
  end
  
  def user_view?
    params[:evaluation] =~ /^user/ 
  end
  
private  

  def setEvaluation
    params[:evaluation] ||= 'userprojects'
    @evaluation = case params[:evaluation].downcase
        when 'managed' then ManagedProjectsEval.new(@user)
        when 'absencedetails' then AbsenceDetailsEval.new
        when 'userprojects' then EmployeeProjectsEval.new(@user.id, @period != nil)
        when "employeesubprojects#{@user.id}", "usersubprojects" then
          params[:evaluation] = 'usersubprojects'
          EmployeeSubProjectsEval.new(params[:category_id], @user.id)
        when 'userabsences' then EmployeeAbsencesEval.new(@user.id)
        when 'subprojects' then SubProjectsEval.new(params[:category_id])
        when 'projectemployees' then ProjectEmployeesEval.new(params[:category_id], @period != nil)
        when 'attendance' then AttendanceEval.new(params[:category_id] || @user.id)
        else nil
    end
    if @user.management && @evaluation.nil?
      @evaluation = case params[:evaluation].downcase
        when 'clients' then ClientsEval.new
        when 'employees' then EmployeesEval.new
        when 'departments' then DepartmentsEval.new
        when 'clientprojects' then ClientProjectsEval.new(params[:category_id])
        when 'employeeprojects' then EmployeeProjectsEval.new(params[:category_id], @period != nil)
        when /employeesubprojects(\d+)/ then EmployeeSubProjectsEval.new(params[:category_id], $1)
        when 'departmentprojects' then DepartmentProjectsEval.new(params[:category_id])
        when 'absences' then AbsencesEval.new
        when 'employeeabsences' then EmployeeAbsencesEval.new(params[:category_id])      
        else nil
      end  
    end
    if @evaluation.nil?
      @evaluation = EmployeeProjectsEval.new(@user.id, false)
    end 
  end
  
  def setEvaluationDetails
    @evaluation.set_division_id(params[:division_id])    
    if params[:start_date] != nil
      @period = params[:start_date] == "0" ? nil :
                   Period.retrieve(params[:start_date], params[:end_date])     
    end     
  end
  
  def setNavigationLevels
    # set session evaluation levels
    session[:evalLevels] = Array.new if params[:clear] || session[:evalLevels].nil?
    levels = session[:evalLevels]
    current = [params[:evaluation], @evaluation.category_id, @evaluation.title]
    levels.pop while levels.any? { |level| pop_level? level, current }  
    levels.push current
  end
  
  def pop_level?(level, current)
    pop = level[0] == current[0]
    if level[0] =~ /(employee|user)?subprojects(\d*)/
      pop &&= level[1] == current[1]
    end
    pop
  end
  
  def paginateTimes
    @time_pages = Paginator.new self, @evaluation.count_times(@period), NO_OF_DETAIL_ROWS, params[:page]
    @times = @evaluation.times(@period, 
                               :limit => @time_pages.items_per_page,
                               :offset => @time_pages.current.offset) 
  end

  def setExportHeader(filename)
    if request.env['HTTP_USER_AGENT'] =~ /msie/i
      headers['Pragma'] = 'public'
      headers['Content-type'] = 'text/plain'
      headers['Cache-Control'] = 'no-cache, must-revalidate, post-check=0, pre-check=0'
      headers['Content-Disposition'] = "attachment; filename=\"#{filename}\""
      headers['Expires'] = '0'
    else
      headers['Content-Type'] ||= 'text/csv'
      headers['Content-Disposition'] = "attachment; filename=\"#{filename}\""
    end
  end
  
  def redirectToOverview
    redirect_to :action => params[:evaluation],
                :category_id => params[:category_id]
  end
  
  def combine_times
    combined_map = {}
    combined_times = []
    @times.each do |time|
      if time.report_type.kind_of?(StartStopType) && params[:start_stop]
        combined_times.push time
      else
        key = "#{time.dateString}$#{time.employee.shortname}" 
        if combined_map.include?(key)
          combined_map[key].hours += time.hours
          if time.description
            if combined_map[key].description
              combined_map[key].description += "\n" + time.description
            else
              combined_map[key].description = time.description
            end  
          end           
        else
          combined_map[key] = time
          combined_times.push time
        end
      end
    end
    @times = combined_times
  end

  def sendCSV(csv_report)
    setExportHeader(csv_report.filename)
    send_data(csv_report.to_csv, :type => 'text/csv; charset=utf-8; header=present', :filename => csv_report.filename)  
  end
  
  def csvLabel(item)
    item.nil? || !item.respond_to?(:label) ? '' : 
      item.label.downcase.gsub(/[^0-9a-z]/, "_") 
  end
  
end
