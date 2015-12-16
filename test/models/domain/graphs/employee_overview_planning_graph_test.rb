require 'test_helper'
class EmployeeOverviewPlanningGraphTest < ActiveSupport::TestCase
  def setup
    @employee = Fabricate(:employee)
    @employment = Fabricate(:employment, employee: @employee, percent: 80)
    @period = Period.new(start_date, start_date + 2.weeks - 1)
  end

  def start_date
    @today ||= Time.zone.today.beginning_of_week
  end

  def week(date)
    "#{date.year}#{date.cweek}"
  end

  def graph(*plannings)
    absence_graph = AbsencePlanningGraph.new([], @period)
    EmployeeOverviewPlanningGraph.new(@employee.reload, Array(plannings), [], absence_graph, @period)
  end

  test '#period_average_employment_percent' do
    assert_equal 80, graph.send(:period_average_employment_percent).to_f

    @employment.update!(end_date: start_date + 6.days)
    assert_equal 40, graph.send(:period_average_employment_percent).to_f

    Fabricate(:employment, employee: @employee, percent: 40, start_date: start_date + 7.days)
    assert_equal 60, graph.send(:period_average_employment_percent).to_f
  end

  test '#period_average_planned_percent' do
    WorkingCondition.clear_cache
    Holiday.refresh
    Planning.delete_all
    # act as if there were no absences/holidays in today's week. this is required
    # for successfull tests even if the current week contains holidays.
    EmployeeOverviewPlanningGraph.any_instance.stubs(:add_absences_to_cache)
    assert_equal 0, graph.period_average_planned_percent.to_f

    planning1 = Fabricate(:planning,
                          employee: @employee,
                          start_week: week(start_date),
                          end_week: week(start_date))
    assert_equal 50, graph(planning1).period_average_planned_percent.to_f

    planning2 = Fabricate(:planning,
                          employee: @employee,
                          start_week: week(start_date + 1),
                          end_week: week(start_date + 1),
                          wednesday_pm: false,
                          thursday_am: false,
                          thursday_pm: false,
                          friday_am: false,
                          friday_pm: false)
    assert_equal 75, graph(planning1, planning2).period_average_planned_percent.to_f

    planning3 = Fabricate(:planning,
                          employee: @employee,
                          start_week: week(start_date - 10),
                          end_week: week(start_date + 10))
    assert_equal 175, graph(planning1, planning2, planning3).period_average_planned_percent.to_f
  end

  test '#period_load' do
    graph = graph()
    graph.stubs(:period_average_employment_percent).returns(50)
    graph.stubs(:period_average_planned_percent).returns(50)
    assert_equal 1, graph.period_load

    graph.stubs(:period_average_planned_percent).returns(25)
    assert_equal 0.5, graph.period_load

    graph.stubs(:period_average_planned_percent).returns(0)
    assert_equal 0, graph.period_load

    graph.stubs(:period_average_planned_percent).returns(100)
    assert_equal 2, graph.period_load

    graph.stubs(:period_average_planned_percent).returns(200)
    assert_equal 4, graph.period_load

    graph.stubs(:period_average_employment_percent).returns(0)
    assert_equal Float::INFINITY, graph.period_load
  end
end
