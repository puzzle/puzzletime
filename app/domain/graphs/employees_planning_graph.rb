# encoding: utf-8

class EmployeesPlanningGraph

  include PeriodIterable

  attr_reader :period
  attr_reader :employee_graphs

  def initialize(employees, period = nil)
    @employees = employees
    period ||= Period.next_three_months
    @actual_period = period
    @period = period.extend_to_weeks
    @colorMap = AccountColorMapper.new

    @employee_graphs = @employees.map { |employee| EmployeePlanningGraph.new(employee, period) }.sort_by {|graph| graph.period_load.to_f }
  end

  def color_for(work_item)
    @colorMap[work_item]
  end

end
