# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class EvaluatorController < ApplicationController

  include ActiveSupport::CoreExtensions::Time::Calculations::ClassMethods
  
  # Checks if employee came from login or from direct url
  before_filter :authorize
  
  # Store the request in the instances variables below.
  # They are needed to get data from the DB.
  def showProjectsPeriod
      @startdate ="#{params[:worktime]['start(3i)']}-#{params[:worktime]['start(2i)']}-#{params[:worktime]['start(1i)']}"      
      @enddate = "#{params[:worktime]['end(3i)']}-#{params[:worktime]['end(2i)']}-#{params[:worktime]['end(1i)']}"
      @startdate_db = "#{params[:worktime]['start(1i)']}-#{params[:worktime]['start(2i)']}-#{params[:worktime]['start(3i)']}"      
      @enddate_db = "#{params[:worktime]['end(1i)']}-#{params[:worktime]['end(2i)']}-#{params[:worktime]['end(3i)']}"
    if @user.management == true
      @projects = Project.find(:all)
    else  
      @projectmemberships = Projectmembership.find(:all, :conditions =>["employee_id = ? AND projectmanagement IS TRUE", @user.id])
    end
  end
  
  # Store the request in the instances variables below.
  # They are needed to get data from the DB.
  def showEmployeesPeriod
    @startdate ="#{params[:worktime]['start(3i)']}-#{params[:worktime]['start(2i)']}-#{params[:worktime]['start(1i)']}"      
    @enddate = "#{params[:worktime]['end(3i)']}-#{params[:worktime]['end(2i)']}-#{params[:worktime]['end(1i)']}"
    @startdate_db = "#{params[:worktime]['start(1i)']}-#{params[:worktime]['start(2i)']}-#{params[:worktime]['start(3i)']}"      
    @enddate_db = "#{params[:worktime]['end(1i)']}-#{params[:worktime]['end(2i)']}-#{params[:worktime]['end(3i)']}"
    @employees = Employee.find(:all)
  end
  
  # Store the request in the instances variables below.
  # They are needed to get data from the DB.
  def showAbsencesPeriod
    @startdate ="#{params[:worktime]['start(3i)']}-#{params[:worktime]['start(2i)']}-#{params[:worktime]['start(1i)']}"      
    @enddate = "#{params[:worktime]['end(3i)']}-#{params[:worktime]['end(2i)']}-#{params[:worktime]['end(1i)']}"
    @startdate_db = "#{params[:worktime]['start(1i)']}-#{params[:worktime]['start(2i)']}-#{params[:worktime]['start(3i)']}"      
    @enddate_db = "#{params[:worktime]['end(1i)']}-#{params[:worktime]['end(2i)']}-#{params[:worktime]['end(3i)']}"
    @employees = Employee.find(:all, :order => "lastname ASC")
    @absences  = Absence.find(:all, :order => "name ASC")
  end
  
  # Store the request in the instances variables below.
  # They are needed to get data from the DB.
  def showClientsPeriod
    @startdate ="#{params[:worktime]['start(3i)']}-#{params[:worktime]['start(2i)']}-#{params[:worktime]['start(1i)']}"      
    @enddate = "#{params[:worktime]['end(3i)']}-#{params[:worktime]['end(2i)']}-#{params[:worktime]['end(1i)']}"
    @startdate_db = "#{params[:worktime]['start(1i)']}-#{params[:worktime]['start(2i)']}-#{params[:worktime]['start(3i)']}"      
    @enddate_db = "#{params[:worktime]['end(1i)']}-#{params[:worktime]['end(2i)']}-#{params[:worktime]['end(3i)']}"
    @clients = Client.find(:all)    
  end
  
  def showDetailTimeAndDate
    if params.has_key?(:startdate)
     
    else
    end
  end
  
  def showDetailWeek
    @project = Project.find(params[:project_id])
    @employee = Employee.find(params[:employee_id])
    @times = Worktime.find(:all, :conditions => ["project_id = ? AND employee_id = ? AND work_date BETWEEN ? AND ?", @project.id, @employee.id, "#{Time.now.year}-#{Time.now.month}-#{Time.now.day-7}", "#{Time.now.year}-#{Time.now.month}-#{Time.now.day}"], :order => "work_date ASC")
  end
  
  def showDetailMonth
    @project = Project.find(params[:project_id])
    @employee = Employee.find(params[:employee_id])
    @times = Worktime.find(:all, :conditions => ["project_id = ? AND employee_id = ? AND  work_date BETWEEN ? AND ?", @project.id, @employee.id, "#{Time.now.year}-#{Time.now.month}-01", "#{Time.now.year}-#{Time.now.month}-#{days_in_month(Time.now.month)}"], :order => "work_date ASC")
  end
  
  def showDetailYear
    @project = Project.find(params[:project_id])
    @employee = Employee.find(params[:employee_id])
    @times = Worktime.find(:all, :conditions => ["project_id = ? AND employee_id = ? AND work_date BETWEEN ? AND ?", @project.id, @employee.id, "#{Time.now.year}-01-01", "#{Time.now.year}-12-31"], :order => "work_date ASC")
  end
  
   def showDetailPeriod
    @project = Project.find(params[:project_id])
    @employee = Employee.find(params[:employee_id])
    @startdate = params[:startdate]
    @enddate = params[:enddate]
    @startdate_db = params[:startdate_db]
    @enddate_db = params[:enddate_db]
    @times = Worktime.find(:all, :conditions => ["project_id = ? AND employee_id = ? AND work_date BETWEEN ? AND ?", @project.id, @employee.id, @startdate_db, @enddate_db ], :order => "work_date ASC")
  end
  
    def showDetailAbsenceWeek
    @absence = Absence.find(params[:absence_id])
    @employee = Employee.find(params[:employee_id])
    @times = Worktime.find(:all, :conditions => ["absence_id = ? AND employee_id = ? AND work_date BETWEEN ? AND ?", @absence.id, @employee.id, "#{Time.now.year}-#{Time.now.month}-#{Time.now.day-7}", "#{Time.now.year}-#{Time.now.month}-#{Time.now.day}"], :order => "work_date ASC")
  end
  
  def showDetailAbsenceMonth
    @absence = Absence.find(params[:absence_id])
    @employee = Employee.find(params[:employee_id])
    @times = Worktime.find(:all, :conditions => ["absence_id = ? AND employee_id = ? AND  work_date BETWEEN ? AND ?", @absence.id, @employee.id, "#{Time.now.year}-#{Time.now.month}-01", "#{Time.now.year}-#{Time.now.month}-#{days_in_month(Time.now.month)}"], :order => "work_date ASC")
  end
  
  def showDetailAbsenceYear
    @absence = Absence.find(params[:absence_id])
    @employee = Employee.find(params[:employee_id])
    @times = Worktime.find(:all, :conditions => ["absence_id = ? AND employee_id = ? AND work_date BETWEEN ? AND ?", @absence.id, @employee.id, "#{Time.now.year}-01-01", "#{Time.now.year}-12-31"], :order => "work_date ASC")
  end
  
   def showDetailAbsencePeriod
    @absence = Absence.find(params[:absence_id])
    @employee = Employee.find(params[:employee_id])
    @startdate = params[:startdate]
    @enddate = params[:enddate]
    @startdate_db = params[:startdate_db]
    @enddate_db = params[:enddate_db]
    @times = Worktime.find(:all, :conditions => ["absence_id = ? AND employee_id = ? AND work_date BETWEEN ? AND ?", @absence.id, @employee.id, @startdate_db, @enddate_db ], :order => "work_date ASC")
  end
  
  def editProjectDetailTime
    @worktime = Worktime.find(params[:worktime_id])
    @absence = Absence.find(:all)
    if params.has_key?(:employee_id)
      @employee = Employee.find(params[:employee_id])
    end   
  end
  
  def editAbsenceDetailTime
    @worktime = Worktime.find(params[:worktime_id])
    @absence = Absence.find(:all)
    if params.has_key?(:employee_id)
      @employee = Employee.find(params[:employee_id])
    end
  end
  

  def updateProjectDetailTime
    @worktime = Worktime.find(params[:worktime_id])
    if params.has_key?(:employee_id)
      @employee = Employee.find(params[:employee_id])
    end
    if @worktime.update_attributes(params[:worktime])
      flash[:notice] = 'Worktime was successfully updated.'
      if params.has_key?(:employee_id)    
        redirect_to :action => 'showProjects', :employee_id => @employee
      else
        redirect_to :controller => 'worktime', :action => 'listTime'
      end
    else
      render :action => 'editTime'
    end
  end
  
  def updateAbsenceDetailTime
    @worktime = Worktime.find(params[:worktime_id])
    if params.has_key?(:employee_id)
      @employee = Employee.find(params[:employee_id])
    end
    if @worktime.update_attributes(params[:worktime])
      flash[:notice] = 'Worktime was successfully updated.'
      if params.has_key?(:employee_id)    
        redirect_to :action => 'showEmployeeProjectAndAbsence', :employee_id => @employee
      else
        redirect_to :controller=>'worktime', :action => 'listTime'
      end
    else
      render :action => 'editAbsenceDetailTime'
    end
  end
  
  # Shows all Projects
  def showProjects
    @projects = Project.find(:all, :order => "name ASC")
    @projectmemberships = Projectmembership.find(:all, :conditions =>["employee_id = ? AND projectmanagement IS TRUE", @user.id])
  end
   
  # Shows all employees
  def showEmployees
    @employees = Employee.find(:all, :order => "lastname ASC")
  end 
  
  # Show all absences
  def showAbsences
    @employees = Employee.find(:all, :order => "lastname ASC")
    @absences  = Absence.find(:all, :order => "name ASC")
  end 
  
  # Show all clients
  def showClients
    @clients = Client.find(:all, :order => "name ASC")
  end
end
