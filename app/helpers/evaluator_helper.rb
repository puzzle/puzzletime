# encoding: utf-8

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

  def detail_td(worktime, field)
    case field
      when :work_date then td f(worktime.work_date), 'right', true
      when :hours then td format_hour(worktime.hours), 'right', true
      when :times then td worktime.time_string, nil, true
      when :employee then td worktime.employee.shortname
      when :account then td worktime.account.label_verbose
      when :billable then td(worktime.billable ? '$' : ' ')
      when :booked then  td(worktime.booked ? '&beta;'.html_safe : ' ')
      when :ticket then  td worktime.ticket
      when :description
        description = worktime.description || ''
        desc = h description.slice(0..40)
        if description.length > 40
          desc += link_to '...', evaluation_detail_params.merge!(
                                  controller: worktime.controller,
                                  action: 'view',
                                  id: worktime.id)
        end
        td desc
      end
  end

  def td(value, align = nil, nowrap = false)
    align = align ? " align=\"#{align}\"" : ''
    style = nowrap ? " style=\"white-space: nowrap;\"" : ''
    "<td#{align}#{style}>#{value}</td>\n".html_safe
  end

  def collect_times(periods, method, *division)
    periods.collect do |p|
      @evaluation.send(method, p, *division)
    end
  end

  def add_time_link(account = nil)
    linkHash = { action: 'new' }
    linkHash[:controller] =  worktime_controller
    if account
      linkHash[:account_id] = account.is_a?(Absence) ? account.id : account.leaves.first.id
    end
    link_to 'Zeit erfassen', linkHash
  end

  def worktime_controller
    @evaluation.absences? ? 'absencetimes' : 'projecttimes' 
  end

  #### division supplement functions

  def complete_link(project)
    link_text = ''
    if @user.projectmemberships.any? { |pm| pm.project == project || pm.project.ancestors.include?(project) }
      link_text = link_to('Komplettieren',
                          { action: 'complete_project',
				                        project_id: project.id,
				                        back_url: request.original_fullpath },
                          method: 'post')
    end
	   link_text +=  ' (' +  f(@user.last_completed(project)) + ')'
    link_text
  end

  def last_completion(employee)
    f(employee.last_completed(@evaluation.category))
  end

  def offered_hours(project)
    offered = project.offered_hours
    if offered
      total = project.worktimes.where(worktimes: { billable: true }).sum(:hours).to_f
      color = 'green'
      if total > offered
        color = 'red'
      elsif total > offered * 0.9
        color = 'orange'
      end
      "#{number_with_precision(offered, precision: 0)} " \
      "(<font color=\"#{color}\">#{format_hour(offered - total)}</font>)".html_safe
    end
  end

  def overtime(employee)
    format_hour(@period ?
        employee.statistics.overtime(@period) :
        employee.statistics.current_overtime) + ' h'
  end

  def remaining_vacations(employee)
    format_hour(@period ?
        employee.statistics.remaining_vacations(@period.endDate) :
        employee.statistics.current_remaining_vacations) + ' d'
  end

  def overtime_vacations_tooltip(employee)
    transfers = employee.overtime_vacations.
                         where(@period ? ['transfer_date <= ?', @period.endDate] : nil).
                         order('transfer_date').
                         to_a
    tooltip = ''
    unless transfers.empty?
      tooltip = '<a href="#" class="tooltip">&lt;-&gt;<span>Überzeit-Ferien Umbuchungen:<br/>'
      transfers.collect! do |t|
        " - #{f(t.transfer_date)}: #{format_hour(t.hours)} h"
      end
      tooltip += transfers.join('<br />')
      tooltip += '</span></a>'
    end
    tooltip.html_safe
  end

  ### period and time helpers

  def period_link(label, shortcut)
    link_to label, action: 'change_period', shortcut: shortcut, back_url: params[:back_url]
  end

  def time_info
    stat = @user.statistics
    infos = @period ?
            [[['Überzeit', stat.overtime(@period).to_f, 'h'],
              ['Bezogene Ferien', stat.used_vacations(@period), 'd'],
              ['Soll Arbeitszeit', stat.musttime(@period), 'h']],
             [['Abschliessend', stat.current_overtime(@period.endDate), 'h'],
              ['Verbleibend', stat.remaining_vacations(@period.endDate), 'd']]]  :
            [[['Überzeit Gestern', stat.current_overtime, 'h'],
              ['Bezogene Ferien', stat.used_vacations(Period.current_year), 'd'],
              ['Monatliche Arbeitszeit', stat.musttime(Period.current_month), 'h']],
             [['Überzeit Heute', stat.current_overtime(Date.today), 'h'],
              ['Verbleibend', stat.current_remaining_vacations, 'd'],
              ['Verbleibend', 0 - stat.overtime(Period.current_month).to_f, 'h']]]
    render partial: 'timeinfo', locals: { infos: infos }
  end

end
