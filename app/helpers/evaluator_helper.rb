# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

module EvaluatorHelper
        
  def init_periods
    if @period
      [@period]
    else 
      periods = user_view? ? @user.user_periods : @user.eval_periods
      periods.collect { |p| Period.parse(p) }
    end
  end 
  
  def detailTD(worktime, field)
    case field
      when :work_date : td format_date(worktime.work_date), 'right'
      when :hours : td number_with_precision(worktime.hours, 2), 'right'
      when :times : td worktime.timeString
      when :employee : td worktime.employee.shortname
      when :account : td worktime.account.label_verbose
      when :billable : td(worktime.billable ? '$' : ' ')
      when :booked :  td(worktime.booked ? '&beta;' : ' ')
      when :description :
        desc = h worktime.description.slice(0..40)
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
    periods.collect do |p| 
      @evaluation.send(method, p, *division) 
    end
  end  
  
  def add_time_link(account = nil)
     linkHash = { :action => 'add' }
     linkHash[:controller] =  worktime_controller 
     if account
       linkHash[:account_id] = account.is_a?(Absence) ? account.id : account.leaves.first.id
     end
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
    offered = project.offered_hours
    if offered
      total = project.worktimes.sum(:hours).to_i
      color = 'green'
      if total > offered
        color = 'red'
      elsif total > offered * 0.9
        color = 'orange'
      end
      "#{number_with_precision(offered, 0)} (<font color=\"#{color}\">#{number_with_precision(offered - total, 0)}</font>)" 
    end
  end
  
  def overtime(employee)
    number_with_precision(@period ? 
        employee.statistics.overtime(@period) : 
        employee.statistics.current_overtime, 2) + ' h'
  end
  
  def remaining_vacations(employee)
    number_with_precision(@period ? 
        employee.statistics.remaining_vacations(@period.endDate) : 
        employee.statistics.current_remaining_vacations, 2) + ' d'
  end
  
  ### period and time helpers

  def period_link(label, shortcut)
    link_to label, evaluation_overview_params( :action => 'changePeriod', :shortcut => shortcut )
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
