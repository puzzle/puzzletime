# encoding: utf-8

class EmployeePlanningGraph

  include PeriodIteratable

  attr_reader :period, :plannings, :plannings_abstr, :work_items, :work_items_abstr, :employee, :overview_graph, :absence_graph

  def initialize(employee, period = nil)
    @employee = employee
    period ||= Period.next_three_months
    @actual_period = period
    @period = period.extend_to_weeks
    @colorMap = AccountColorMapper.new
    employee_plannings = Planning.where('start_week <= ?', Week.from_date(@period.end_date).to_integer).
                                  where(employee_id: @employee.id)
    @plannings       = employee_plannings.where(is_abstract: false).includes(:work_item, :employee)
    @plannings_abstr = employee_plannings.where(is_abstract: true).includes(:work_item, :employee)
    @work_items       = collect_work_items(@plannings)
    @work_items_abstr = collect_work_items(@plannings_abstr)
    absences = Absencetime.where('employee_id = ? AND work_date >= ? AND work_date <= ?',
                                 @employee.id, @period.start_date, @period.end_date)
    @absence_graph = AbsencePlanningGraph.new(absences, @period)
    @overview_graph = EmployeeOverviewPlanningGraph.new(@employee, @plannings, @plannings_abstr, absence_graph, @period)
  end

  def collect_work_items(plannings)
    plannings.select { |planning| planning.planned_during?(@period) }.
              collect { |planning| planning.work_item }.
              uniq.
              sort
  end

end
