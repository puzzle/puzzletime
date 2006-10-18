# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz


class EvaluatorController < ApplicationController
  
  # Checks if employee came from login or from direct url
  before_filter :authorize
  
  def listEvaluator
  end
  
  def showHoliday
    @employees = Employee.find(:all)
  end
  
  def showEmployeeProjectAndAbsence
    @employees = Employee.find(:all)
  end
  
  def showProjects
    @employee = Employee.find(params[:employee_id])
    if params.has_key?(:employee_id) 
      @employee_projects = @employee.projects
    else
      @employee_projects = @user.projects
    end
  end
  
  def showProjectDetailTime
    @project = Project.find(params[:project_id])
    @startdate ="#{params[:worktime]['start(3i)']}-#{params[:worktime]['start(2i)']}-#{params[:worktime]['start(1i)']}"      
    @enddate = "#{params[:worktime]['end(3i)']}-#{params[:worktime]['end(2i)']}-#{params[:worktime]['end(1i)']}"
    startdate = "#{params[:worktime]['start(1i)']}-#{params[:worktime]['start(2i)']}-#{params[:worktime]['start(3i)']}"      
    enddate= "#{params[:worktime]['end(1i)']}-#{params[:worktime]['end(2i)']}-#{params[:worktime]['end(3i)']}"  
    if params.has_key?(:employee_id)
      @employee = Employee.find(params[:employee_id])
     else
      @employee = @user
     end
      @times = Worktime.find(:all, :conditions => ["project_id = ? and employee_id = ? AND work_date BETWEEN ? AND ?", @project.id, @employee.id, startdate, enddate])
      @sum_period_time =  Worktime.sum(:hours, :conditions => ["project_id = ? and employee_id = ? AND work_date BETWEEN ? AND ?", @project.id, @employee.id, startdate, enddate])
  end
  
  def selectProjectDetailTime
     @project = Project.find(params[:project_id])
     if params.has_key?(:employee_id)
       @employee = Employee.find(params[:employee_id])
     end    
  end
  
  def selectAbsenceDetailTime
     if params.has_key?(:employee_id)
       @employee = Employee.find(params[:employee_id])
     end    
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
  
  def showAbsenceDetailTime
    startdate = "#{params[:worktime]['start(1i)']}-#{params[:worktime]['start(2i)']}-#{params[:worktime]['start(3i)']}"      
    enddate = "#{params[:worktime]['end(1i)']}-#{params[:worktime]['end(2i)']}-#{params[:worktime]['end(3i)']}"
    if params.has_key?(:employee_id)
      @employee = Employee.find(params[:employee_id])
    else
      @employee = @user
    end
      @absence_times = Worktime.find(:all, :conditions => ["employee_id = ? AND work_date BETWEEN ? AND ? AND project_id IS NULL", @employee.id, startdate, enddate], :order => 'work_date DESC') 
      @sum_absence_time = Worktime.sum(:hours, :conditions =>["employee_id = ? AND work_date BETWEEN ? AND ? AND project_id IS NULL", @employee.id, startdate, enddate])
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
  
  def showProjectgroups
    @projects = Project.find(:all)
    @projectmemberships = Projectmembership.find(:all, :conditions =>["employee_id = ? AND projectmanagement IS TRUE", @user.id])
   end
end
