# encoding: utf-8

class EmployeesPlanningGraph

  include PeriodIteratable

  attr_reader :period
  attr_reader :employees

  def initialize(employees, period = nil)
    @employees = employees.sort
    period ||= Period.next_three_months
    @actual_period = period
    @period = period.extend_to_weeks
    @colorMap = AccountColorMapper.new

    @employees.each do |employee|
      cache[employee] = EmployeePlanningGraph.new(employee, period)
    end
  end

  def graph_for(user)
    cache[user]
  end

  def color_for(work_item)
    @colorMap[work_item]
  end

end
