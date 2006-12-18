# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class EvaluatorController < ApplicationController
 
  # Checks if employee came from login or from direct url.
  before_filter :authenticate
  before_filter :authorize, :only => [:clients, :employees, :absences, 
                                      :clientProjects, :employeeProjects, :employeeAbsences]
  before_filter :setPeriod
  
  def clients
    @evaluation = Evaluation.clients
    render :action => 'overview'
  end
  
  def employees
    @evaluation = Evaluation.employees
    render :action => 'overview'
  end
  
  def absences
    @evaluation = Evaluation.absences
    render :action => 'overview'
  end
  
  def managed
    @evaluation = Evaluation.managedProjects(@user)
    render :action => 'overview'
  end
  
  def clientProjects
    @evaluation = Evaluation.clientProjects(params[:category_id])
    render :action => 'overview'
  end
  
  def projectEmployees
    @evaluation = Evaluation.projectEmployees(params[:category_id])
    render :action => 'overview'
  end
  
  def employeeProjects
    @evaluation = Evaluation.employeeProjects(params[:category_id])
    render :action => 'overview'
  end 
    
  def employeeAbsences
    @evaluation = Evaluation.employeeAbsences(params[:category_id])
    render :action => 'overview'
  end
  
  def userProjects
    @evaluation = Evaluation.employeeProjects(@user.id)
    render :action => 'userOverview'
  end
  
  def userAbsences
    @evaluation = Evaluation.employeeAbsences(@user.id)
    render :action => 'userOverview'
  end
  
  def details  
    setEvaluation
    @evaluation.set_division_id(params[:division_id])
    if params[:start_date] != nil
      if params[:start_date] == "0"
        @period = nil
      else  
        @period = Period.new(Date.parse(params[:start_date]), Date.parse(params[:end_date]))     
      end  
      session[:period] = @period 
    end
    
    @times = @evaluation.times(@period)
  end
  
  # Shows overtimes of employees
  def overtime
    authorize
    @employees = Employee.list
  end
  
  def description
    @time = Worktime.find(params[:worktime_id])
  end
  
  def currentPeriod
    session[:period] = nil
    redirect_to :action => params[:evaluation],
                :category_id => params[:category_id]
  end
  
  def changePeriod
    begin
      @period = Period.new(parseDate(params[:period], 'startDate'), 
                           parseDate(params[:period], 'endDate'))  
      raise ArgumentError, "start date after end date" if @period.negative?   
      session[:period] = @period  
      redirect_to :action => params[:evaluation],
                  :category_id => params[:category_id]              
    rescue ArgumentError => ex
      flash[:notice] = "Invalid period: " + ex
      redirect_to :action => :selectPeriod, 
                  :evaluation => params[:evaluation],
                  :category_id => params[:category_id]
    end       
  end
  
private  

  def setEvaluation
    if ! @user.management &&
      (params[:evaluation] == 'clients' ||
       params[:evaluation] == 'absences' ||
       params[:evaluation] == 'clientprojects' ||
       params[:evaluation] == 'employeeprojects' ||
       params[:evaluation] == 'employeeabsences' ||
       params[:evaluation] == 'employees') then
        params[:evaluation] = 'managed'
    end  
  
    @evaluation = case params[:evaluation].downcase
      when 'clients' then Evaluation.clients
      when 'managed' then Evaluation.managedProjects(@user)
      when 'employees' then Evaluation.employees
      when 'absences' then Evaluation.absences
      when 'userprojects' then Evaluation.employeeProjects(@user.id)
      when 'userabsences' then Evaluation.employeeAbsences(@user.id)
      when 'clientprojects' then Evaluation.clientProjects(params[:category_id])
      when 'employeeprojects' then Evaluation.employeeProjects(params[:category_id])
      when 'employeeabsences' then Evaluation.employeeAbsences(params[:category_id])
      when 'projectemployees' then Evaluation.projectEmployees(params[:category_id])
      else Evaluation.managedProjects(@user)
      end  
  end
  
  def setPeriod
    @period = session[:period]
  end
    
  def parseDate(attributes, prefix)
     Date.new(attributes[prefix + '(1i)'].to_i, 
              attributes[prefix + '(2i)'].to_i, 
              attributes[prefix + '(3i)'].to_i)
  end
  
end
