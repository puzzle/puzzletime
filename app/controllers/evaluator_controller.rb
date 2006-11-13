# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class EvaluatorController < ApplicationController
 
  # Used for the method days_in_month.
  include ActiveSupport::CoreExtensions::Time::Calculations::ClassMethods
  
  # Checks if employee came from login or from direct url.
  before_filter :authorize
  
  @@categories = [Employee, Project, Client, Absence]
  @@subdivisions = [:projects, :absences, :employees]
  @@defaultMatrix = {:category => Employee, :division => :projects}
     
  def userOverview
     setPeriod
     setMatrix
     @matrix[:category] = Employee
     @id = @user.id
  end   
     
  def overview
    setPeriod
    setMatrix    
  end
  
  def details
    setPeriod
    setMatrix
    @category = @matrix[:category].find(params[:category_id])
    @subdivision = @category.send(@matrix[:division]).find(params[:division_id])
    @times = @subdivision.worktimesBy(@period, @category.subdivisionRef)    
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
  
  # Shows overtimes of employees
  def showOvertime
    @employees = Employee.find(:all, :order =>"lastname ASC")
  end
  
  def showDescription
    @time = Worktime.find(params[:worktime_id])
  end
  
private  
    
  def setPeriod
    @period = nil
    if params.has_key?(:start_date)
      @period = Period.new(Date.parse(params[:start_date]), Date.parse(params[:end_date]))
    elsif params.has_key?(:worktime)
      @period = Period.new(parseDate(params[:worktime], 'start'), 
                           parseDate(params[:worktime], 'end'))  
    end  
  end
  
  def setMatrix
    @matrix = @@defaultMatrix
    @@categories.each { |ea|     
      @matrix[:category] = ea if ea.name == params[:category]
    }
    @@subdivisions.each { |ea|   
      @matrix[:division] = ea if ea.to_s == params[:division]
    }
  end
end
