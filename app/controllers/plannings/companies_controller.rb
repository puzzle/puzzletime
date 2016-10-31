module Plannings
  class CompaniesController < ApplicationController

    include WithPeriod

    before_action :authorize_action
    before_action :set_period

    def show
      @boards = sort_boards_by_workload(create_boards)
    end

    private

    def create_boards
      employees = Employee.employed_ones(@period).list
      employees.map { |e| Plannings::EmployeeBoard.new(e, @period) }
    end

    def sort_boards_by_workload(boards)
      monthly_employment_percent = {}
      boards.each do |board|
        monthly_employment_percent[board] = board.week_totals
                                                 .values
                                                 .inject(0, :+)
      end
      boards.sort do |a, b|
        monthly_employment_percent[a] <=> monthly_employment_percent[b]
      end
    end

    def set_period
      convert_predefined_period
      period = super
      period = default_period unless period.limited?
      @period = period.extend_to_weeks
    end

    def convert_predefined_period
      return if params[:period].blank?

      @period = Period.parse(params.delete(:period))
      if @period
        params[:start_date] = I18n.l(@period.start_date)
        params[:end_date] = I18n.l(@period.end_date)
      end
    end

    def default_period
      Period.next_n_months(3)
    end

    def authorize_action
      authorize!(:read, Planning)
    end

  end
end
