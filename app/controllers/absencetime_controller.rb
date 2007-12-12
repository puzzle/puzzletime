class AbsencetimeController < WorktimeController
  
  def addMultiAbsence
    setAccounts
    @multiabsence = MultiAbsence.new
  end
    
  def createMultiAbsence
    @multiabsence = MultiAbsence.new
    @multiabsence.employee = @user    
    @multiabsence.attributes = params[:multiabsence]
    if @multiabsence.valid?
      count = @multiabsence.save   
      flash[:notice] = "#{count} Absenzen wurden erfasst"
      options = { :controller => 'evaluator', 
                  :action => detailAction, 
                  :evaluation => userEvaluation,
                  :clear => 1 }
      setPeriod           
      if @period.nil? || 
          (! @period.include?(@multiabsence.start_date) ||
          ! @period.include?(@multiabsence.end_date))
        options[:start_date] = @multiabsence.start_date
        options[:end_date] = @multiabsence.end_date  
      end
      redirect_to options  
    else
      setAccounts
      render :action => 'addMultiAbsence'
    end  
  end  
  
protected

  def setNewWorktime
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