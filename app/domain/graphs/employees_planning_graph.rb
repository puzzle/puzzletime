# encoding: utf-8

class EmployeesPlanningGraph
  include PeriodIterable

  attr_reader :period
  attr_reader :employee_graphs

  def initialize(employees, period = nil, sort_by_load = false)
    @employees = employees
    period ||= Period.next_three_months
    @actual_period = period
    @period = period.extend_to_weeks
    @colorMap = AccountColorMapper.new

    sort_attr = sort_by_load ? :period_load : :employee
    @employee_graphs = @employees.map { |employee| EmployeePlanningGraph.new(employee, period) }.sort_by(&sort_attr)
  end

  def color_for(work_item)
    @colorMap[work_item]
  end
end
