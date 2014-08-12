# encoding: utf-8

class EmployeePlanningGraph
  # TODO separate view helpers from this class
  include PlanningHelper

  attr_reader :period, :plannings, :plannings_abstr, :projects, :projects_abstr, :employee, :overview_graph, :absence_graph

  def initialize(employee, period = nil)
    @employee = employee
    period ||= Period.current_month
    @actual_period = period
    @period = extend_to_weeks(period)
    @cache = {}
    @colorMap = AccountColorMapper.new
    employee_plannings = Planning.where('start_week <= ?', Week.from_date(@period.end_date).to_integer).
                                  where(employee_id: @employee.id)
    @plannings       = employee_plannings.where(is_abstract: false).includes(:project, :employee)
    @plannings_abstr = employee_plannings.where(is_abstract: true).includes(:project, :employee)
    @projects       = collect_projects(@plannings)
    @projects_abstr = collect_projects(@plannings_abstr)
    absences = Absencetime.where('employee_id = ? AND work_date >= ? AND work_date <= ?',
                                 @employee.id, @period.start_date, @period.end_date)
    @absence_graph = AbsencePlanningGraph.new(absences, @period)
    @overview_graph = EmployeeOverviewPlanningGraph.new(@employee, @plannings, @plannings_abstr, absence_graph, @period)
  end

  def collect_projects(plannings)
    plannings.select { |planning| planning.planned_during?(@period) }.
              collect { |planning| planning.project }.
              uniq.
              sort
  end

end
