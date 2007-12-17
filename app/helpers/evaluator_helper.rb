# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

module EvaluatorHelper
        
  def init_periods
    if @period
      [@period]
    else 
      if user_view?
        [Period.currentDay, Period.currentWeek, Period.currentMonth]
      else
        [Period.currentWeek, Period.currentMonth, Period.currentYear]
      end
    end
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
    all_periods(periods).collect do |p| 
      @evaluation.send(method, p, *division) 
    end
  end  
  
  def all_periods(periods)
    all_periods = periods
    all_periods += [nil] if !user_view?
    all_periods
  end
  
  def add_time_link(account = nil)
     linkHash = { :action => 'add' }
     linkHash[:controller] =  worktime_controller 
     linkHash[:account_id] = account.id if account
     link_to 'Zeit erfassen', linkHash 
  end
  
  def worktime_controller
    case 
      when @evaluation.absences? : 'absencetime'
      when @evaluation.kind_of?(AttendanceEval) : 'attendancetime'
      else 'projecttime'
      end 
  end

  #### division supplement functions

  def complete_link(project)
     link_to('Komplettieren', 
	           evaluation_overview_params(:action => 'completeProject', 
					                               :project_id => project.id),
             :method => 'post' ) + 
		' (' +  format_date(@user.lastCompleted(project)) + ')'		                
  end

  def last_completion(employee)
    format_date employee.lastCompleted(@evaluation.category)
  end

  def offered_hours(project)
    number_with_precision(project.offered_hours, 2)
  end
  
  ### period and time helpers

  def period_link(label, periodMethod, date)
    period = Period.send(periodMethod, date)
    link_to label, evaluation_overview_params( :action => 'changePeriod',
                         'period[startDate]' => period.startDate.strftime(DATE_FORMAT),
                         'period[endDate]' => period.endDate.strftime(DATE_FORMAT),
                         'period[label]' => label )
  end
  
  def timeInfo
    stat = @user.statistics
    infos = @period ?    
            [[['&Uuml;berzeit', stat.overtime(@period).to_f, 'h'],
              ['Bezogene Ferien', stat.used_vacations(@period), 'd']],
             [['Soll Arbeitszeit', stat.musttime(@period), 'h'], 
              ['Verbleibend', stat.remaining_vacations(@period.endDate), 'd']]]  :
            [[['&Uuml;berzeit Gestern', stat.current_overtime, 'h'],
              ['Bezogene Ferien', stat.used_vacations(Period.currentYear), 'd'],
              ['Monatliche Arbeitszeit', stat.musttime(Period.currentMonth), 'h']],
             [['&Uuml;berzeit Heute', stat.current_overtime(Date.today), 'h'],
              ['Verbleibend', stat.current_remaining_vacations, 'd'],
              ['Verbleibend', 0 - stat.overtime(Period.currentMonth).to_f, 'h']]]   
    render :partial => 'timeinfo', :locals => {:infos => infos}
  end
 
end
