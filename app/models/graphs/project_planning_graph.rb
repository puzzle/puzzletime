# encoding: utf-8

class ProjectPlanningGraph

  include PlanningHelper

  attr_reader :period, :project, :overview_graph, :employees, :employees_abstr, :plannings, :plannings_abstr

  def initialize(project, period = nil)
    @project = project
    period ||= Period.currentMonth
    @period = extend_to_weeks period
    @cache = {}
    @plannings       = Planning.where('project_id = ? and start_week <= ? and is_abstract=false', @project.id, Week.from_date(period.endDate).to_integer)
    @plannings_abstr = Planning.where('project_id = ? and start_week <= ? and is_abstract=true', @project.id, Week.from_date(period.endDate).to_integer)
    @employees       = @plannings.select { |planning| planning.planned_during?(@period) }.collect { |planning| planning.employee }.uniq.sort
    @employees_abstr = @plannings_abstr.select { |planning| planning.planned_during?(@period) }.collect { |planning| planning.employee }.uniq.sort
    @overview_graph = ProjectOverviewPlanningGraph.new(@project, @plannings, @plannings_abstr, @period)
  end

  def get_absence_graph(employee_id)
    absences = Absencetime.where('employee_id = ? AND work_date >= ? AND work_date <= ?', employee_id, @period.startDate, @period.endDate)
    AbsencePlanningGraph.new(absences, @period)
  end

end
