module Plannings
  class CompanyOverview

    attr_reader :period, :boards

    def initialize(period)
      @period = period
      @boards = create_boards.sort_by { |b| -b.overall_free_capacity }
    end

    def week_totals_state(date)
      Plannings::EmployeeBoard.week_totals_state(week_total(date), weekly_employment_percent(date))
    end

    def week_total(date)
      @week_total ||= {}
      @week_total[date] ||= boards.sum { |board| board.week_total(date) }
    end

    def weekly_employment_percent(date)
      @weekly_employment_percent ||= {}
      @weekly_employment_percent[date] ||=
          boards.sum { |board| board.weekly_employment_percent(date) }
    end

    private

    def create_boards
      employees = Employee.employed_ones(period).list
      employees.map { |e| Plannings::EmployeeBoard.new(e, period) }
    end

  end
end