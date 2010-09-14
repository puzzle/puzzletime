
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
      exportCSV(create_capacity_csv, "puzzletime_auslastung")
    else
      flash[:notice] = "Bitte wählen Sie eine Zeitspanne für die detaillierte Auslastung."
      redirect_to :back
    end
  end
  
  def exportExtendedCapacityCSV
    if @period
      exportCSV(create_extended_capacity_csv, "puzzletime_detaillierte_auslastung")
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

  def exportCSV(csv_data, filename_prefix)
    filename = "#{filename_prefix}_#{@period.startDate.strftime("%Y%m%d")}_#{@period.endDate.strftime("%Y%m%d")}.csv"
    setExportHeader(filename)
    send_data(csv_data, :type => 'text/csv; charset=utf-8; header=present', :filename => filename)  
  end
  
  def csvLabel(item)
    item.nil? || !item.respond_to?(:label) ? '' : 
      item.label.downcase.gsub(/[^0-9a-z]/, "_") 
  end
  
  def create_extended_capacity_csv
    FasterCSV.generate do |csv|
      # header
      csv << ["Mitarbeiter",
              "Soll Arbeitszeit (h)",
              "Überzeit (h)",
              "Überzeit Total (h)",
              "Ferienguthaben bis Ende #{Date.today.year} (h)",
              "Zusätzliche Anwesenheit (h)",
              "Abwesenheit (h)",
              "Projekte Total (h)",
              "Subprojektname",
              "Projekte Total verrechenbar (h)",
              "Projekte Total nicht verrechenbar (h)",
              "Interne Projekte Total (h)"]
      
      Employee.employed_ones(@period).each do |employee|
        # prepare employee data
        project_total_billable_hours = 0      # Projekte Total verrechenbar (h)
        project_total_non_billable_hours = 0  # Projekte Total nicht verrechenbar (h)
        internal_project_total_hours = 0      # Interne Projekte Total (h)
        
        processed_ids = []
        billable_projects = []
        non_billable_projects = []
        employee.worked_on_projects.each do |project|
          # get id of parent project on (max) level 1
          id = project.path_ids[[1, project.path_ids.size - 1].min]
          if ! processed_ids.include? id
            processed_ids.push id
            project = Project.find(id)
            if project.billable
              billable_projects.push project
            else
              non_billable_projects.push project
            end
          end 
        end

        # line per billable project
        csv_billable_lines = []
        billable_projects.each do |project|
          result = find_billable_time(employee, project.id, @period)
          sum = result.collect { |w| w.hours }.sum  
          parent = child = project
          parent = child.parent if child.parent
          
          project_billable_hours = extract_billable_hours(result, true)
          project_total_billable_hours += project_billable_hours
          project_non_billable_hours = extract_billable_hours(result, false)
          project_total_non_billable_hours += project_non_billable_hours
          
          if (project_billable_hours+project_non_billable_hours).abs > 0.001
            csv_billable_lines << [employee.shortname, "", "", "", "", "", "",
                    parent.label_verbose, 
                    child == parent ? "" : child.label,
                    project_billable_hours, 
                    project_non_billable_hours,
                    "-"]
          end
        end
      
        # line per non-billable project
        csv_non_billable_lines = []
        non_billable_projects.each do |project|
          result = find_billable_time(employee, project.id, @period)
          sum = result.collect { |w| w.hours }.sum  
          parent = child = project
          parent = child.parent if child.parent
          
          internal_project_hours = extract_billable_hours(result, false)
          internal_project_total_hours += internal_project_hours
          
          if internal_project_hours.abs > 0.001
            csv_non_billable_lines << [employee.shortname, "", "", "", "", "", "",
                    parent.label_verbose, 
                    child == parent ? "" : child.label,
                    "-", 
                    "-", 
                    internal_project_hours]
          end
        end
        
        project_total_hours = project_total_billable_hours + project_total_non_billable_hours + internal_project_total_hours
        diff = employee.sumAttendance(@period) - project_total_hours
        additional_attendance_hours = diff.abs > 0.001 ? diff : 0
        
        # first line: employee overview
        csv << [employee.shortname,                                     # Mitarbeiter
                employee.statistics.musttime(@period),                  # Soll Arbeitszeit (h)
                employee.statistics.overtime(@period),                  # Überzeit (h)
                employee.statistics.current_overtime,                   # Überzeit Total (h)
                employee.statistics.current_remaining_vacations,        # Ferienguthaben bis Ende Jahr (h)
                additional_attendance_hours,                            # Zusätzliche Anwesenheit (h)
                employee_absences(employee, @period),                   # Abwesenheit (h)
                project_total_hours,                                    # Projekte Total (h)
                "-",                                                    # Subprojektname
                project_total_billable_hours,                           # Projekte Total verrechenbar (h)
                project_total_non_billable_hours,                       # Projekte Total nicht verrechenbar (h)
                internal_project_total_hours]                           # Interne Projekte Total (h)
        
        # append prepared data to CSV
        csv_billable_lines.each do |line|
          csv << line
        end
        csv_non_billable_lines.each do |line|
          csv << line
        end
      end
    end
  end
  
  def create_capacity_csv
    periods = monthly_periods
    FasterCSV.generate do |csv|
      csv << ["Mitarbeiter", "Projekt", "Subprojekt", "Verrechenbar", "Nicht verrechenbar", "Monat", "Jahr"]
      Employee.employed_ones(@period).each do |employee|
        periods.each do |period|
          project_time = 0
          processed_ids = []
          employee.worked_on_projects.each do |project|
            # get id of parent project on (max) level 1
            id = project.path_ids[[1, project.path_ids.size - 1].min]
            if ! processed_ids.include? id
              processed_ids.push id
              result = find_billable_time(employee, id, period)
              sum = result.collect { |w| w.hours }.sum  
              parent = child = Project.find(id)
              parent = child.parent if child.parent
              append_account_entry(csv, 
                        employee, 
                        period, 
                        parent.label_verbose, 
                        child == parent ? "" : child.label,
                        extract_billable_hours(result, true), 
                        extract_billable_hours(result, false))
              project_time += sum
            end  
          end
          # include Anwesenheitszeit Differenz
          diff = employee.sumAttendance(period) - project_time
          append_account_entry(csv, employee, period, "Zusätzliche Anwesenheit", "", 0, diff)
          # include all absencetimes
          absences = employee_absences(employee, period)
          append_account_entry(csv, employee, period, "Abwesenheiten", "", 0, absences)
        end  
      end  
    end 
  end
  
  def employee_absences(employee, period)
   employee.worktimes.sum(:hours, 
                          :include => :absence,
                          :conditions => ["type = 'Absencetime' AND absences.payed AND work_date BETWEEN ? AND ?", 
                                          period.startDate, 
                                          period.endDate]).to_f
  end
  
  def append_account_entry(csv, employee, period, project_label, subproject_label, billable_hours, not_billable_hours)
    if (billable_hours + not_billable_hours).abs > 0.001
      csv << [employee.shortname, 
              project_label,
              subproject_label,
              billable_hours, 
              not_billable_hours,
              period.startDate.month, 
              period.startDate.year]
    end
  end
  
  def find_billable_time(employee, project_id, period)
    Worktime.find_by_sql ["""SELECT SUM(w.hours) AS HOURS, w.billable FROM worktimes w 
                             LEFT JOIN projects p ON p.id = w.project_id
                             WHERE w.employee_id = ? AND ? = ANY(p.path_ids)
                             AND w.work_date BETWEEN ? AND ?
                             GROUP BY w.billable""",
                          employee.id, project_id, period.startDate, period.endDate ]  
  end
  
  def monthly_periods
    month_end = @period.startDate.end_of_month
    periods = [Period.new(@period.startDate, [month_end, @period.endDate].min)]
    while @period.endDate > month_end
      month_start = month_end + 1
      month_end = month_start.end_of_month
      periods.push Period.new(month_start, [month_end, @period.endDate].min)
    end
    periods
  end
  
  def extract_billable_hours(result, billable)
    entry = result.select {|w| w.billable == billable }.first
    entry ? entry.hours : 0
  end
  
end
