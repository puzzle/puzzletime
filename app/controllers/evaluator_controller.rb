# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class EvaluatorController < ApplicationController
 
  # Checks if employee came from login or from direct url.
  before_filter :authenticate
  before_filter :setPeriod
  
  def overview
    setEvaluation       
    if @evaluation.for?(@user)
      render :action => 'userOverview'
    end
  end 
  
  def details  
    setEvaluation
    @evaluation.set_detail_ids(params[:category_id], params[:division_id])
    puts @evaluation.division_label
    if params[:start_date] != nil
      @period = Period.new(Date.parse(params[:start_date]), Date.parse(params[:end_date]))
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
    redirect_to :action => params[:return_action], :evaluation => params[:evaluation]
  end
  
  def changePeriod
    begin
      @period = Period.new(parseDate(params[:period], 'startDate'), 
                           parseDate(params[:period], 'endDate'))  
      raise ArgumentError, "start date after end date" if @period.negative?   
      session[:period] = @period                
    rescue ArgumentError => ex
      flash[:notice] = "Invalid period: " + ex
      redirect_to :action => :selectPeriod, 
               :return_action => params[:action],
               :evaluation => params[:evaluation]
    end   
    redirect_to :action => params[:return_action], :evaluation => params[:evaluation]
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
    @period = session[:period]
  end
    
  def parseDate(attributes, prefix)
     Date.new(attributes[prefix + '(1i)'].to_i, 
              attributes[prefix + '(2i)'].to_i, 
              attributes[prefix + '(3i)'].to_i)
  end
  
end
