# encoding: utf-8

class EmployeePlanningGraph
  include PeriodIterable

  attr_reader :period, :plannings, :plannings_abstr, :work_items, :work_items_abstr, :employee, :overview_graph, :absence_graph

  delegate :period_load, to: :overview_graph

  def initialize(employee, period = Period.next_n_months(3))
    @employee = employee
    @actual_period = period
    @period = period.extend_to_weeks
    @colorMap = AccountColorMapper.new
    employee_plannings = Planning.where('date <= ?', @period.end_date).
                         where(employee_id: @employee.id)
    @plannings       = employee_plannings.includes(:work_item, :employee)
    @work_items       = collect_work_items(@plannings)
    absences = Absencetime.where('employee_id = ? AND work_date >= ? AND work_date <= ?',
                                 @employee.id, @period.start_date, @period.end_date)
    @absence_graph = AbsencePlanningGraph.new(absences, @period)
    @overview_graph = EmployeeOverviewPlanningGraph.new(@employee, @plannings, absence_graph, @period)
  end

  def collect_work_items(plannings)
    plannings.
      collect(&:work_item).
      uniq.
      sort
  end
end
