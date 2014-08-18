# encoding: utf-8

class ProjectPlanningGraph


  # TODO separate view helpers from this class
  include PlanningHelper

  attr_reader :period, :project, :overview_graph, :employees, :employees_abstr, :plannings, :plannings_abstr

  def initialize(project, period = nil)
    @project = project
    period ||= Period.current_month
    @period = extend_to_weeks period
    @cache = {}
    @plannings       = Planning.where('project_id = ? and start_week <= ? and is_abstract=false',
                                      @project.id,
                                      Week.from_date(period.end_date).to_integer).
                                includes(:project, :employee)
    @plannings_abstr = Planning.where('project_id = ? and start_week <= ? and is_abstract=true',
                                      @project.id,
                                      Week.from_date(period.end_date).to_integer).
                                includes(:project, :employee)
    @employees       = @plannings.select { |planning| planning.planned_during?(@period) }.collect { |planning| planning.employee }.uniq.sort
    @employees_abstr = @plannings_abstr.select { |planning| planning.planned_during?(@period) }.collect { |planning| planning.employee }.uniq.sort
    @overview_graph = ProjectOverviewPlanningGraph.new(@project, @plannings, @plannings_abstr, @period)
  end

  def get_absence_graph(employee_id)
    absences = Absencetime.where('employee_id = ? AND work_date >= ? AND work_date <= ?', employee_id, @period.start_date, @period.end_date)
    AbsencePlanningGraph.new(absences, @period)
  end

end
