# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz


class EvaluatorController < ApplicationController
  
  # Checks if employee came from login or from direct url
  before_filter :authorize
  
  def listEvaluator
    @employees = Employee.find(:all)
    @absences = Absence.find(:all)
  end
  
  def showHoliday
    @employees = Employee.find(:all)
  end
  
  def showEmployeeProjects
    @employees = Employee.find(:all)
  end
  
  def showProjects
    @employee = Employee.find(params[:id])
    @employee_projects = @employee.projects
  end
  
  def showProjectDetailTime
     @project = Project.find(params[:project_id])
     if params.has_key?(:employee_id)
       @employee = Employee.find(params[:employee_id])
       @times = Worktime.find(:all, :conditions => ["project_id = ? and employee_id = ?", @project.id, @employee.id])
     else
       @user = Employee.find(params[:user_id])
       @times = Worktime.find(:all, :conditions => ["project_id = ? and employee_id = ?", @project.id, @user.id])   
     end
  end
  
  def editProjectDetailTime
    @project = Project.find(params[:project_id])
    @worktime = Worktime.find(params[:worktime_id])
    @absence = Absence.find(:all)
    if params.has_key?(:employee_id)
      @employee = Employee.find(params[:employee_id])
    else
      @user.id
    end
  end

  def updateProjectDetailTime
    @project = Project.find(params[:project_id])
    @worktime = Worktime.find(params[:worktime_id])
    if params.has_key?(:employee_id)
      @employee = Employee.find(params[:employee_id])
    end
    if @worktime.update_attributes(params[:worktime])
      flash[:notice] = 'Worktime was successfully updated.'
      if params.has_key?(:employee_id)    
        redirect_to :action => 'showProjectDetailTime', :project_id => @project, :employee_id => @employee
      else
        redirect_to :action => 'showProjectDetailTime', :project_id => @project, :user_id => @user.id
      end
    else
      render :action => 'editTime'
    end
  end
end
