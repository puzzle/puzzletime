# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class EvaluatorController < ApplicationController
  
  # Checks if employee came from login or from direct url
  before_filter :authorize
  
  # Store the request in the instances variables below.
  # They are needed to get data of the DB.
  def showProjectsPeriod
    @startdate ="#{params[:worktime]['start(3i)']}-#{params[:worktime]['start(2i)']}-#{params[:worktime]['start(1i)']}"      
    @enddate = "#{params[:worktime]['end(3i)']}-#{params[:worktime]['end(2i)']}-#{params[:worktime]['end(1i)']}"
    @startdate_db = "#{params[:worktime]['start(1i)']}-#{params[:worktime]['start(2i)']}-#{params[:worktime]['start(3i)']}"      
    @enddate_db = "#{params[:worktime]['end(1i)']}-#{params[:worktime]['end(2i)']}-#{params[:worktime]['end(3i)']}"
    @projects = Project.find(:all)
    @projectmemberships = Projectmembership.find(:all, :conditions =>["employee_id = ? AND projectmanagement IS TRUE", @user.id])
  end
  
  # Store the request in the instances variables below.
  # They are needed to get data of the DB.
  def showEmployeesPeriod
    @startdate ="#{params[:worktime]['start(3i)']}-#{params[:worktime]['start(2i)']}-#{params[:worktime]['start(1i)']}"      
    @enddate = "#{params[:worktime]['end(3i)']}-#{params[:worktime]['end(2i)']}-#{params[:worktime]['end(1i)']}"
    @startdate_db = "#{params[:worktime]['start(1i)']}-#{params[:worktime]['start(2i)']}-#{params[:worktime]['start(3i)']}"      
    @enddate_db = "#{params[:worktime]['end(1i)']}-#{params[:worktime]['end(2i)']}-#{params[:worktime]['end(3i)']}"
    @employees = Employee.find(:all)
  end
  
  # Store the request in the instances variables below.
  # They are needed to get data of the DB.
  def showAbsencesPeriod
    @startdate ="#{params[:worktime]['start(3i)']}-#{params[:worktime]['start(2i)']}-#{params[:worktime]['start(1i)']}"      
    @enddate = "#{params[:worktime]['end(3i)']}-#{params[:worktime]['end(2i)']}-#{params[:worktime]['end(1i)']}"
    @startdate_db = "#{params[:worktime]['start(1i)']}-#{params[:worktime]['start(2i)']}-#{params[:worktime]['start(3i)']}"      
    @enddate_db = "#{params[:worktime]['end(1i)']}-#{params[:worktime]['end(2i)']}-#{params[:worktime]['end(3i)']}"
    @employees = Employee.find(:all, :order => "lastname ASC")
    @absences  = Absence.find(:all, :order => "name ASC")
  end
  
  # Store the request in the instances variables below.
  # They are needed to get data of the DB.
  def showClientsPeriod
    @startdate ="#{params[:worktime]['start(3i)']}-#{params[:worktime]['start(2i)']}-#{params[:worktime]['start(1i)']}"      
    @enddate = "#{params[:worktime]['end(3i)']}-#{params[:worktime]['end(2i)']}-#{params[:worktime]['end(1i)']}"
    @startdate_db = "#{params[:worktime]['start(1i)']}-#{params[:worktime]['start(2i)']}-#{params[:worktime]['start(3i)']}"      
    @enddate_db = "#{params[:worktime]['end(1i)']}-#{params[:worktime]['end(2i)']}-#{params[:worktime]['end(3i)']}"
    @clients = Client.find(:all)    
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
