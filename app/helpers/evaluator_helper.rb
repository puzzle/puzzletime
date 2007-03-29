# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

module EvaluatorHelper
        
  def init_periods
    @period.nil? ? 
      [Period.currentWeek, Period.currentMonth, Period.currentYear] : 
      [@period]
  end 
  
  def collect_times(periods, method, *division)
    times = periods.collect { |p| @evaluation.send(method, p, *division) }
    times.push(@evaluation.send(method, nil, *division))
    times
  end  
  
  def add_time_link(account = nil)
     linkHash = { :action => 'add' }
     linkHash[:controller] =  @evaluation.absences? ? 'absencetime' : 'projecttime'   
     linkHash[:account_id] = account.id if account
     link_to 'Zeit erfassen', linkHash 
  end

  def complete_link(project)
     link_to 'Komplettieren', 
	     evaluation_overview_params(:action => 'completeProject', 
					                :project_id => project.id)
  end

  def last_completion(employee)
    format_date employee.lastCompleted(@evaluation.category)
  end

  def period_link(label, periodMethod, date)
    period = Period.send(periodMethod, date)
    link_to label, evaluation_overview_params( :action => 'changePeriod',
                         'period[startDate]' => period.startDate.strftime(DATE_FORMAT),
                         'period[endDate]' => period.endDate.strftime(DATE_FORMAT),
                         'period[label]' => label )
  end
  
  def timeInfo
    infos = @period ?    
            [[['Soll Arbeitszeit', @user.musttime(@period), 'h'],
              ['Bezogene Ferien', @user.usedVacations(@period), 'd']],
             [['&Uuml;berzeit', @user.overtime(@period).to_f, 'h'], 
              ['Offen', @user.remainingVacations(@period.endDate), 'd']]]  :
            [[['Monatliche Arbeitszeit', @user.musttime(Period.currentMonth), 'h'],
              ['&Uuml;berzeit Gestern', @user.currentOvertime, 'h'],
              ['Geplante Ferien', @user.usedVacations(Period.currentYear), 'd']],
             [['Verbleibend', 0 - @user.overtime(Period.currentMonth).to_f, 'h'],
              ['&Uuml;berzeit Heute', @user.currentOvertime(Date.today), 'h'],
              ['Verbleibend', @user.currentRemainingVacations, 'd']]]   
    render :partial => 'timeinfo', :locals => {:infos => infos}
  end
  
end
