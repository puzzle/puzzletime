# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

require 'fastercsv'

class EvaluatorController < ApplicationController
 
  # Checks if employee came from login or from direct url.
  before_filter :authenticate
  before_filter :authorize, :only => [:clients, :employees, :overtime,
                                      :clientProjects, :employeeProjects, :employeeAbsences ]
  before_filter :setPeriod
  
  def index
    overview
  end
  
  def overview
    params[:evaluation] = params[:action] if ! params[:evaluation]
    setEvaluation
    
    # set session evaluation levels
    session[:evalLevels] = Array.new if params[:clear]
    levels = session[:evalLevels]
    current = [@evaluation, params[:evaluation]]
    levels.pop while params[:up] && levels.last != current
    levels.push current if levels.last != current
    
    render :action => (params[:evaluation] =~ /^user/ ? 'userOverview' : 'overview' )
  end
  
  def details  
    setEvaluation
    @evaluation.set_division_id(params[:division_id])    
    if params[:start_date] != nil
      @period = params[:start_date] == "0" ? nil :
                   Period.new(Date.parse(params[:start_date]), Date.parse(params[:end_date]))     
    end
    
    @time_pages = Paginator.new self, @evaluation.count_times(@period), NO_OF_DETAIL_ROWS, params[:page]
    @times = @evaluation.times(@period, 
                               :limit => @time_pages.items_per_page,
                               :offset => @time_pages.current.offset)                               
  end
  
  def attendanceDetails
    eval = params[:evaluation]
    params[:evaluation] = 'attendance'
    details    
    params[:evaluation] = eval
    render :action => 'details' 
  end
    
  # Shows overtimes of employees
  def overtime
    @employees = Employee.list
  end
  
  def report
    setEvaluation
    @evaluation.set_division_id(params[:division_id])
    if params[:start_date] != nil
      @period = params[:start_date] == "0" ? nil :
                   Period.new(Date.parse(params[:start_date]), Date.parse(params[:end_date]))     
    end
    @times = @evaluation.times(@period)
    render :layout => false
  end
  
  def exportCSV
    setEvaluation
    @evaluation.set_division_id(params[:division_id])

    filename = "puzzletime_" + csvLabel(@evaluation.category) + "-" +
               csvLabel(@evaluation.division) + ".csv"
    setExportHeader(filename)
    
    csv_string = FasterCSV.generate do |csv|
      csv << ["Datum", "Stunden", "Start Zeit", "End Zeit", "Reporttyp",
              "Verrechenbar", "Mitarbeiter", "Projekt", "Beschreibung"]
      @evaluation.times(@period).each do |time|
        csv << [ time.work_date.strftime(DATE_FORMAT),
                 time.hours,
                 (time.startStop? ? time.from_start_time.strftime("%H:%M") : ''),
                 (time.startStop? ? time.to_end_time.strftime("%H:%M") : ''),
                 time.report_type,
                 time.billable,
                 time.employee.label,
                 (time.account ? time.account.label : 'Anwesenheitszeit'),
                 time.description ]
      end
    end 
    send_data(csv_string,
              :type => 'text/csv; charset=utf-8; header=present',
              :filename => filename)  
  end
  
  def selectPeriod
    @period = Period.new()
  end
  
  def currentPeriod
    session[:period] = nil
    redirect_to :action => params[:evaluation],
                :category_id => params[:category_id]
  end
  
  def changePeriod
    @period = Period.new(params[:period][:startDate], 
                         params[:period][:endDate],
                         params[:period][:label])  
    raise ArgumentError, "Start Datum nach End Datum" if @period.negative?   
    session[:period] = @period  
    redirect_to :action => params[:evaluation],
                :category_id => params[:category_id]              
  rescue ArgumentError => ex
    flash[:notice] = "Ung&uuml;ltige Zeitspanne: " + ex
    redirect_to :action => :selectPeriod, 
                :evaluation => params[:evaluation],
                :category_id => params[:category_id]      
  end

  def completeProject
    pm = @user.projectmemberships.find(:first, 
            :conditions => ["project_id = ?", params[:project_id]])
    pm.update_attributes(:last_completed => Date.today)
    flash[:notice] = "Das Datum der kompletten Erfassung aller Zeiten für das Projekt #{pm.project.label_verbose} wurde aktualisiert."
    redirect_to :action => params[:evaluation], 
                :category_id => params[:category_id]
  end
  
  def calendar
  
  end
  
  def method_missing(action, *args)
    params[:evaluation] = action.to_s
    overview
  end
  
private  

  def setEvaluation
    @evaluation = case params[:evaluation].downcase
        when 'managed' then ManagedProjectsEval.new(@user)
        when 'managedabsences' then ManagedAbsencesEval.new(@user)
        when 'absences' then AbsencesEval.new
        when 'userprojects' then EmployeeProjectsEval.new(@user.id)
        when 'userabsences' then EmployeeAbsencesEval.new(@user.id)        
        when 'projectemployees' then ProjectEmployeesEval.new(params[:category_id])
        when 'attendance' then AttendanceEval.new(params[:category_id] || @user.id)
        else nil
        end
    if @user.management && @evaluation.nil?
      @evaluation = case params[:evaluation].downcase
        when 'clients' then ClientsEval.new
        when 'employees' then EmployeesEval.new
        when 'clientprojects' then ClientProjectsEval.new(params[:category_id])
        when 'employeeprojects' then EmployeeProjectsEval.new(params[:category_id])
        when 'employeeabsences' then EmployeeAbsencesEval.new(params[:category_id])
        else nil
        end  
    end
    if @evaluation.nil?
      @evaluation = EmployeeProjectsEval.new(@user.id)
    end 
  end
  
  def setPeriod
    @period = session[:period]
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
  
  def csvLabel(item)
    item.nil? || !item.respond_to?(:label) ? '' : 
      item.label.downcase.gsub(/[^0-9a-z]/, "_") 
  end
  
end
