class AbsencetimeController < WorktimeController
  
  def list
    # reload user absences
    @user.absences(true)
    redirect_to :controller => 'evaluator', :action => 'userAbsences'
  end
  
  def addMultiAbsence
    @accounts = Absence.list
    @multiabsence = MultiAbsence.new
  end
    
  def createMultiAbsence
    @multiabsence = MultiAbsence.new
    @multiabsence.employee = @user    
    @multiabsence.attributes = params[:multiabsence]
    if @multiabsence.valid?
      count = @multiabsence.save   
      flash[:notice] = "#{count} Absenzen wurden erfasst"
      @user.absences(true)      #true forces reload

      options = { :controller => 'evaluator', :action => 'details', 
                  :evaluation => 'userAbsences'}
      puts session[:period].nil?
      if session[:period].nil? || 
          (! session[:period].include?(@multiabsence.start_date) ||
          ! session[:period].include?(@multiabsence.end_date))
        options[:start_date] = @multiabsence.start_date
        options[:end_date] = @multiabsence.end_date  
      end
      puts options.inspect
      redirect_to options  
    else
      @accounts = Absence.list
      render :action => 'addMultiAbsence'
    end  
  end
  
  
protected

  def setWorktime
    @worktime = Absencetime.new   
  end
  
  def setWorktimeAccount
    @worktime.absence_id = params[:account_id]
  end

  def setAccounts
    @accounts = Absence.list 
  end  
  
  def userEvaluation
    @user.absences(true)
    'userAbsences'
  end
  
end