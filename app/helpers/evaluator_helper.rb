#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module EvaluatorHelper
  def evaluation_detail_params
    params.permit(:evaluation, :category_id, :division_id, :absence_id, :start_date, :end_date, :page)
  end

  def evaluation_path(evaluation, options = {})
    url_for(options.merge(controller: '/evaluator', action: 'overview', evaluation:))
  end

  def detail_th_align(field)
    case field
    when :work_date, :hours, :times then 'right'
    end
  end

  def detail_td(worktime, field)
    case field
    when :work_date then content_tag(:td, f(worktime.work_date), class: 'right nowrap', style: 'width: 160px;')
    when :hours then content_tag(:td, format_hour(worktime.hours), class: 'right nowrap', style: 'width: 70px;')
    when :times then content_tag(:td, worktime.time_string, class: 'right nowrap', style: 'width: 150px;')
    when :employee then content_tag(:td, worktime.employee.shortname, style: 'width: 50px;')
    when :account then content_tag(:td, worktime.account.label_verbose)
    when :billable then content_tag(:td, worktime.billable ? '$' : ' ', style: 'width: 20px;')
    when :ticket then content_tag(:td, worktime.ticket)
    when :description
      content_tag(:td, worktime.description, title: worktime.description, class: 'truncated')
    end
  end

  def collect_times(evaluation, periods, method, *division)
    periods.collect do |p|
      evaluation.send(method, p, *division)
    end
  end

  def times_or_plannings?(evaluation, division, times)
    @periods.each_with_index.any? do |_p, i|
      time = times[i][division.id]
      val = (time.is_a?(Hash) ? time[:hours] : time).to_f
      if evaluation.planned_hours
        plan = @plannings[i][division.id]
        val += (plan.is_a?(Hash) ? plan[:hours] : 0).to_f
      end
      val > 0.001
    end
  end

  def worktime_controller
    @evaluation.absences? ? 'absencetimes' : 'ordertimes'
  end

  #### division supplement functions

  def overtime(employee)
    value = if @period
              employee.statistics.overtime(@period)
            else
              employee.statistics.current_overtime
            end
    format_hour(value)
  end

  def remaining_vacations(employee)
    value = if @period
              employee.statistics.remaining_vacations(@period.end_date)
            else
              employee.statistics.current_remaining_vacations
            end
    format_days(value)
  end

  def overtime_vacations_tooltip(employee)
    transfers = employee.overtime_vacations.
                where(@period ? ['transfer_date <= ?', @period.end_date] : nil).
                order('transfer_date').
                to_a
    tooltip = ''
    unless transfers.empty?
      tooltip = '<a href="#" class="has-tooltip">&lt;-&gt;<span>Überstunden-Ferien Umbuchungen:<br/>'
      transfers.collect! do |t|
        " - #{f(t.transfer_date)}: #{format_hour(t.hours)}"
      end
      tooltip += transfers.join('<br />')
      tooltip += '</span></a>'
    end
    tooltip.html_safe
  end

  def worktime_commits_readonly(employee)
    worktime_commits(employee, false)
  end

  def worktime_reviews_readonly(employee)
    worktime_reviews(employee, false)
  end

  def worktime_commits(employee, editable = can?(:update_committed_worktimes, employee))
    completable_cell("committed_worktimes_at_#{employee.id}",
                     employee.committed_worktimes_at,
                     editable,
                     edit_employee_worktimes_commit_path(employee),
                     'Freigabe bearbeiten')
  end

  def worktime_reviews(employee, editable = can?(:update_reviewed_worktimes, employee))
    completable_cell("reviewed_worktimes_at_#{employee.id}",
                     employee.reviewed_worktimes_at,
                     editable,
                     edit_employee_worktimes_review_path(employee),
                     'Kontrolle bearbeiten')
  end

  def order_completed(work_item)
    order = work_item.order
    completable_cell("order_completed_#{order.id}",
                     order.completed_at,
                     can?(:update_completed, order),
                     edit_order_completed_path(order),
                     'Monatsabschluss erledigen')
  end

  def order_committed(work_item)
    order = work_item.order
    completable_cell("order_committed_#{order.id}",
                     order.committed_at,
                     can?(:update_committed, order),
                     edit_order_committed_path(order),
                     'Monatsabschluss freigeben')
  end

  def completable_cell(content_id, date, editable, edit_path, edit_title)
    content = content_tag(:span,
                          completed_icon(date) << ' ' << format_month(date),
                          id: content_id)

    if editable
      content <<
        ' &nbsp; '.html_safe <<
        link_to(picon('edit'),
                edit_path,
                data: { modal: '#modal',
                        title: edit_title,
                        update: 'element',
                        element: "##{content_id}",
                        remote: true,
                        type: :html })
    end

    content
  end

  ### info helpers

  def employment_role_infos(employment)
    employment
      .employment_roles_employments
      .includes(:employment_role, :employment_role_level)
      .order('percent DESC')
      .map do |ere|
        role = ere.employment_role.name
        role += ' ' + ere.employment_role_level.name if ere.employment_role_level.present?
        [role, ere.percent]
      end
  end

  def employee_info_workload_report_employee_entry(employee)
    period = @period || Period.current_month
    worktimes = employee_info_worktimes(employee, period)
    Reports::Workload::EmployeeEntry.new(employee, period, [], worktimes)
  end

  def employee_info_worktimes(employee, period)
    Worktime
      .in_period(period)
      .joins(
        'LEFT OUTER JOIN work_items ON work_items.id = worktimes.work_item_id'
      )
      .joins('LEFT OUTER JOIN absences ON absences.id = worktimes.absence_id')
      .joins(:employee)
      .where(employee_id: employee.id)
      .pluck(*Reports::Workload::WORKTIME_FIELDS)
      .map { |w| Reports::Workload::WorktimeEntry.new(*w) }
  end
end
