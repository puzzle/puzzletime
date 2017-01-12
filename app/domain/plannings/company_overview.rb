module Plannings
  class CompanyOverview

    attr_reader :period, :boards

    def initialize(period)
      @period = period
      @boards = create_boards.sort_by { |b| -b.overall_free_capacity }
    end

    def week_planning_state(date)
      Plannings::EmployeeBoard.week_planning_state(weekly_planned_percent(date), weekly_employment_percent(date))
    end

    def weekly_planned_percent(date)
      @weekly_planned_percent ||= {}
      @weekly_planned_percent[date] ||= boards.sum { |board| board.weekly_planned_percent(date) }
    end

    def weekly_employment_percent(date)
      @weekly_employment_percent ||= {}
      @weekly_employment_percent[date] ||=
        boards.sum { |board| board.weekly_employment_percent(date).to_f }
    end

    private

    def create_boards
      employees = Employee.employed_ones(period).list
      employees.map { |e| Plannings::EmployeeBoard.new(e, period) }
    end

  end
end
