# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class EvaluatorController < ApplicationController
 
  # Checks if employee came from login or from direct url.
  before_filter :authenticate
  
  def overview
    setEvaluation
    setPeriod        
    if @evaluation.for?(@user)
      render :action => 'userOverview'
    end
  end 
  
  def details  
    setEvaluation
    setPeriod
    @category = @evaluation.category(params[:category_id].to_i)
    @subdivision = @evaluation.division(@category, params[:division_id].to_i)
    @times = @subdivision.worktimesBy(@period, @category.subdivisionRef)    
  end
  
  # Shows overtimes of employees
  def overtime
    authorize
    @employees = Employee.list
  end
  
  def description
    @time = Worktime.find(params[:worktime_id])
  end
  
private  

  def setEvaluation
    if ! @user.management &&
      (params[:evaluation] == 'clients' ||
      params[:evaluation] == 'employees') then
        params[:evaluation] = 'managed'
    end  
  
    @evaluation = case params[:evaluation]
      when 'clients' then Evaluation.clients
      when 'managed' then Evaluation.managed(@user)
      when 'employees' then Evaluation.employees
      when 'absences' then Evaluation.absences
      when 'user' then Evaluation.user(@user)
      when 'userabsences' then Evaluation.userAbsences(@user)
      else Evaluation.managed(@user)
      end  
  end

  def setPeriod
    @period = nil
    if params.has_key?(:start_date)
      @period = Period.new(Date.parse(params[:start_date]), Date.parse(params[:end_date]))
    elsif params.has_key?(:period)
      begin
        @period = Period.new(parseDate(params[:period], 'startDate'), 
                           parseDate(params[:period], 'endDate'))  
        raise ArgumentError, "start date after end date" if @period.negative?                   
      rescue ArgumentError => ex
        flash[:notice] = "Invalid period: " + ex
        redirect_to :action => :selectPeriod, 
               :return_action => params[:action],
               :evaluation => params[:evaluation]
      end                       
    end  
  end
    
  def parseDate(attributes, prefix)
     Date.new(attributes[prefix + '(1i)'].to_i, 
              attributes[prefix + '(2i)'].to_i, 
              attributes[prefix + '(3i)'].to_i)
  end
  
end
