# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

module EvaluatorHelper
        
  def init_periods
    @period.nil? ? 
      [Period.currentWeek, Period.currentMonth, Period.currentYear] : 
      [@period]
  end 
  
  def detailTD(worktime, field)
    case field
      when :work_date : td format_date(worktime.work_date), 'right'
      when :hours : td number_with_precision(worktime.hours, 2), 'right'
      when :times : td worktime.timeString
      when :employee : td worktime.employee.shortname
      when :account : td worktime.account.label_verbose
      when :billable : td(worktime.billable ? 'j' : 'n')
      when :description :
        desc = worktime.description.slice(0..40)
        if worktime.description.length > 40
          desc += link_to '...', evaluation_detail_params.merge!({
                                  :controller => worktime.controller, 
                                  :action => 'view', 
                                  :id => worktime.id})
        end                          
        td desc
      end
  end
  
  def td(value, align = nil)
    align = align ? " align=\"#{align}\"" : ""
    "<td#{align}>#{value}</td>\n"
  end
  
  def collect_times(periods, method, *division)
    (periods + [nil]).collect do |p| 
      @evaluation.send(method, p, *division) 
    end
  end  
  
  def add_time_link(account = nil)
     linkHash = { :action => 'add' }
     linkHash[:controller] =  case 
                                when @evaluation.absences? : 'absencetime'
                                when @evaluation.kind_of?(AttendanceEval) : 'attendancetime'
                                else 'projecttime'
                                end   
     linkHash[:account_id] = account.id if account
     link_to 'Zeit erfassen', linkHash 
  end

  def complete_link(project)
     link_to('Komplettieren', 
	          evaluation_overview_params(:action => 'completeProject', 
					                     :project_id => project.id)) + 
		' (' +  format_date(@user.lastCompleted(project)) + ')'		                
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
            [[['&Uuml;berzeit', @user.overtime(@period).to_f, 'h'],
              ['Bezogene Ferien', @user.usedVacations(@period), 'd']],
             [['Soll Arbeitszeit', @user.musttime(@period), 'h'], 
              ['Offen', @user.remainingVacations(@period.endDate), 'd']]]  :
            [[['&Uuml;berzeit Gestern', @user.currentOvertime, 'h'],
              ['Geplante Ferien', @user.usedVacations(Period.currentYear), 'd'],
              ['Monatliche Arbeitszeit', @user.musttime(Period.currentMonth), 'h']],
             [['&Uuml;berzeit Heute', @user.currentOvertime(Date.today), 'h'],
              ['Verbleibend', @user.currentRemainingVacations, 'd'],
              ['Verbleibend', 0 - @user.overtime(Period.currentMonth).to_f, 'h']]]   
    render :partial => 'timeinfo', :locals => {:infos => infos}
  end
 
end
