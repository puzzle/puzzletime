# encoding: utf-8

class EmployeesPlanningGraph

  # TODO separate view helpers from this class
  include PlanningHelper

  attr_reader :period
  attr_reader :employees

  def initialize(employees, period = nil)
    @employees = employees.sort
    period ||= Period.current_month
    @actual_period = period
    @period = extend_to_weeks period
    @cache = {}
    @colorMap = AccountColorMapper.new

    @employees.each do |employee|
      @cache[employee] = EmployeePlanningGraph.new(employee, period)
    end

  end

  def graph_for(user)
    @cache[user]
  end

  def color_for(project)
    @colorMap[project]
  end

end
