# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

module EvaluatorHelper
        
  def init_periods
    @period.nil? ? 
      [Period.currentWeek, Period.currentMonth, Period.currentYear] : 
      [@period]
  end 
  
  def collect_times(periods, sum_periods, division)
    times = periods.collect { |p| @evaluation.sum_times(p, division) }
    times.push(@evaluation.sum_times(nil, division))
    sum_periods.each_index { |i| sum_periods[i] += times[i] }
    times
  end   

  def add_time_link(division = nil)
     addAction = @evaluation.absences? ? 'addAbsence' : 'addTime'
     account = ''
     if division
       account = @evaluation.absences? ? 'absence_id' : 'project_id'
       account = "?#{account}=#{division.id}"
     end  
     "<a href=\"/worktime/#{addAction}#{account}\">Zeit erfassen</a>"  
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
            [[['Arbeitszeit', @user.musttime(@period), 'h'],
              ['&Uuml;berzeit', @user.overtime(@period).to_f, 'h']],
             [['Bezogene Ferien', @user.usedVacations(@period), 'd'], 
              ['Offen', @user.remainingVacations(@period.endDate), 'd']]]  :
            [[['Monatliche Arbeitszeit', @user.musttime(Period.currentMonth), 'h'],
              ['Verbleibend', 0 - @user.overtime(Period.currentMonth).to_f, 'h']],
             [['&Uuml;berzeit Gestern', @user.currentOvertime, 'h'], 
              ['&Uuml;berzeit Heute', @user.currentOvertime(Date.today), 'h']],
             [['Geplante Ferien', @user.usedVacations(Period.currentYear), 'd'], 
              ['Verbleibend', @user.currentRemainingVacations, 'd']]]   
    render :partial => 'timeinfo', :locals => {:infos => infos}
  end
  
end