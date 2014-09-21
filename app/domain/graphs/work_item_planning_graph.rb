# encoding: utf-8

class WorkItemPlanningGraph


  # TODO separate view helpers from this class
  include PlanningHelper

  attr_reader :period, :work_item, :overview_graph, :employees, :employees_abstr, :plannings, :plannings_abstr

  def initialize(work_item, period = nil)
    @work_item = work_item
    period ||= Period.current_month
    @period = extend_to_weeks period
    @cache = {}
    @plannings       = Planning.where('work_item_id = ? and start_week <= ? and is_abstract=false',
                                      @work_item.id,
                                      Week.from_date(period.end_date).to_integer).
                                includes(:work_item, :employee)
    @plannings_abstr = Planning.where('work_item_id = ? and start_week <= ? and is_abstract=true',
                                      @work_item.id,
                                      Week.from_date(period.end_date).to_integer).
                                includes(:work_item, :employee)
    @employees       = @plannings.select { |planning| planning.planned_during?(@period) }.collect { |planning| planning.employee }.uniq.sort
    @employees_abstr = @plannings_abstr.select { |planning| planning.planned_during?(@period) }.collect { |planning| planning.employee }.uniq.sort
    @overview_graph = WorkItemOverviewPlanningGraph.new(@work_item, @plannings, @plannings_abstr, @period)
  end

  def get_absence_graph(employee_id)
    absences = Absencetime.where('employee_id = ? AND work_date >= ? AND work_date <= ?', employee_id, @period.start_date, @period.end_date)
    AbsencePlanningGraph.new(absences, @period)
  end

end
