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
    if @evaluation.for?(@user) then render :action => 'userOverview' 
    else render :action => 'overview'
    end
  end
  
  def details  
    setEvaluation
    @evaluation.set_division_id(params[:division_id])
    if params[:start_date] != nil
      @period = params[:start_date] == "0" ? nil :
                   Period.new(Date.parse(params[:start_date]), Date.parse(params[:end_date]))     
       #session[:period] = @period 
    end
    
    @time_pages = Paginator.new self, @evaluation.count_times(@period), NO_OF_DETAIL_ROWS, params[:page]
    @times = @evaluation.times(@period, 
                                :limit => @time_pages.items_per_page,
                                :offset => @time_pages.current.offset)
  end
  
  # Shows overtimes of employees
  def overtime
    @employees = Employee.list
  end
  
  def description
    @time = Worktime.find(params[:worktime_id])
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
                 (time.times? ? time.from_start_time.strftime("%H:%M") : ''),
                 (time.times? ? time.to_end_time.strftime("%H:%M") : ''),
                 time.report_type,
                 time.billable,
                 time.employee.label,
                 time.account.label,
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
  
  def method_missing(action, *args)
    params[:evaluation] = action.to_s
    overview
  end
  
private  

  def setEvaluation
    @evaluation = case params[:evaluation].downcase
        when 'managed' then Evaluation.managedProjects(@user)
        when 'managedabsences' then Evaluation.managedAbsences(@user)
        when 'absences' then Evaluation.absences
        when 'userprojects' then Evaluation.employeeProjects(@user.id)
        when 'userabsences' then Evaluation.employeeAbsences(@user.id)        
        when 'projectemployees' then Evaluation.projectEmployees(params[:category_id])
        else nil
        end
    if @user.management && @evaluation.nil?
      @evaluation = case params[:evaluation].downcase
        when 'clients' then Evaluation.clients
        when 'employees' then Evaluation.employees
        when 'clientprojects' then Evaluation.clientProjects(params[:category_id])
        when 'employeeprojects' then Evaluation.employeeProjects(params[:category_id])
        when 'employeeabsences' then Evaluation.employeeAbsences(params[:category_id])
        else nil
        end  
    end
    if @evaluation.nil?
      @evaluation = Evaluation.employeeProjects(@user.id)
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
