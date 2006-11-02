# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class EvaluatorController < ApplicationController
 
  # Used for the method days_in_month.
  include ActiveSupport::CoreExtensions::Time::Calculations::ClassMethods
  
  # Checks if employee came from login or from direct url.
  before_filter :authorize
  
  # Store the request in the instances variables below.
  # They are needed to get data from the DB.
  def showProjectsPeriod
    setPeriodDates
    if @user.management 
      @projects = Project.find(:all)
    else  
      @projectmemberships = Projectmembership.find(:all, :conditions =>["employee_id = ? AND projectmanagement IS TRUE", @user.id])
    end
  end
  
  # Store the request in the instances variables below.
  # They are needed to get data from the DB.
  def showEmployeesPeriod
    setPeriodDates
    @employees = Employee.find(:all)
  end
  
  # Sets the selected periodDates 
  def setPeriodDates
    @startdate = "#{params[:worktime]['start(3i)']}-#{params[:worktime]['start(2i)']}-#{params[:worktime]['start(1i)']}"
    @enddate = "#{params[:worktime]['end(3i)']}-#{params[:worktime]['end(2i)']}-#{params[:worktime]['end(1i)']}"
    @startdate_db = "#{params[:worktime]['start(1i)']}-#{params[:worktime]['start(2i)']}-#{params[:worktime]['start(3i)']}"
    @enddate_db = "#{params[:worktime]['end(1i)']}-#{params[:worktime]['end(2i)']}-#{params[:worktime]['end(3i)']}"
  end
  
  # Store the request in the instances variables below.
  # They are needed to get data from the DB.
  def showAbsencesPeriod
    setPeriodDates
    @employees = Employee.find(:all, :order => "lastname ASC")
    @absences  = Absence.find(:all, :order => "name ASC")
  end
  
  # Store the request in the instances variables below.
  # They are needed to get data from the DB.
  def showClientsPeriod
    setPeriodDates
    @clients = Client.find(:all)    
  end
  
  # showDetail queries for current times
  def showDetail(startdate, enddate)
    @project = Project.find(params[:project_id])
    @employee = Employee.find(params[:employee_id])
    @times = Worktime.find(:all, :conditions => ["project_id = ? AND employee_id = ? AND work_date BETWEEN ? AND ?", @project.id, @employee.id, startdate, enddate], :order => "work_date ASC")
  end
    
  # Shows project detail of current week.
  def showDetailWeek
    showDetail(startCurrentWeek(Date.today), endCurrentWeek(Date.today))
  end
  
  # Shows project detail of current month.
  def showDetailMonth
    showDetail("#{Time.now.year}-#{Time.now.month}-01", "#{Time.now.year}-#{Time.now.month}-#{days_in_month(Time.now.month)}")
  end
  
  # Shows project detail of current year.
  def showDetailYear
    showDetail("#{Time.now.year}-01-01", "#{Time.now.year}-12-31")
  end
 
  # Shows project detail of selected period.
  def showDetailPeriod
    @project = Project.find(params[:project_id])
    @employee = Employee.find(params[:employee_id])
    @startdate = params[:startdate]
    @enddate = params[:enddate]
    @startdate_db = params[:startdate_db]
    @enddate_db = params[:enddate_db]
    @times = Worktime.find(:all, :conditions => ["project_id = ? AND employee_id = ? AND work_date BETWEEN ? AND ?", @project.id, @employee.id, @startdate_db, @enddate_db ], :order => "work_date ASC")
  end
  
  # Shows detail query
  def showDetailAbsence(startdate,enddate)
    @absence = Absence.find(params[:absence_id])
    @employee = Employee.find(params[:employee_id])
    @times = Worktime.find(:all, :conditions => ["absence_id = ? AND employee_id = ? AND work_date BETWEEN ? AND ?", @absence.id, @employee.id, startdate, enddate], :order => "work_date ASC")
  end
  # Shows absence detail of current week.
  def showDetailAbsenceWeek
    showDetailAbsence(startCurrentWeek(Date.today), endCurrentWeek(Date.today))
  end
  
  # Shows absence detail of current month.
  def showDetailAbsenceMonth
    showDetailAbsence("#{Time.now.year}-#{Time.now.month}-01", "#{Time.now.year}-#{Time.now.month}-#{days_in_month(Time.now.month)}")
  end
  
  # showAbsence queries for current times
  def showDetailAbsenceYear
    showDetailAbsence("#{Time.now.year}-01-01", "#{Time.now.year}-12-31")
  end
  
  # Shows absence detail of selected period.
  def showDetailAbsencePeriod 
    @absence = Absence.find(params[:absence_id])
    @employee = Employee.find(params[:employee_id])
    @startdate = params[:startdate]
    @enddate = params[:enddate]
    @startdate_db = params[:startdate_db]
    @enddate_db = params[:enddate_db]
    @times = Worktime.find(:all, :conditions => ["absence_id = ? AND employee_id = ? AND work_date BETWEEN ? AND ?", @absence.id, @employee.id, @startdate_db, @enddate_db ], :order => "work_date ASC")
  end
  
  # Shows project edit detail page.
  def editProjectDetailTime
    @worktime = Worktime.find(params[:worktime_id])
    @absence = Absence.find(:all) 
  end
  
  # Shows absence edit detail page.
  def editAbsenceDetailTime
    @worktime = Worktime.find(params[:worktime_id])
    @absence = Absence.find(:all)
    if params.has_key?(:employee_id)
      @employee = Employee.find(params[:employee_id])
    end
  end
  
  # Shows all projects.
  def showProjects
    @projects = Project.find(:all, :order => "name ASC")
    @projectmemberships = Projectmembership.find(:all, :conditions =>["employee_id = ? AND projectmanagement IS TRUE", @user.id])
  end
   
  # Shows all employees.
  def showEmployees
    @employees = Employee.find(:all, :order => "lastname ASC")
  end 
  
  # Shows all absences.
  def showAbsences
    @employees = Employee.find(:all, :order => "lastname ASC")
    @absences  = Absence.find(:all, :order => "name ASC")
  end 
  
  # Shows all clients.
  def showClients
    @clients = Client.find(:all, :order => "name ASC")
  end
  
  # Shows overtimes of employees
  def showOvertime
    @employees = Employee.find(:all, :order =>"lastname ASC")
  end
  
  def showDescription
    @time = Worktime.find(params[:worktime_id])
  end
end
