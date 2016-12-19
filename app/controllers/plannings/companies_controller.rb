module Plannings
  class CompaniesController < ApplicationController

    include WithPeriod

    self.allow_unlimited_period = false

    before_action :authorize_action
    before_action :set_period

    def show
      @overview = Plannings::CompanyOverview.new(@period)
    end

    private

    def set_period
      period = build_period
      if period.nil?
        period = session[:planning_period] || default_period
      elsif period.unlimited?
        period = default_period
      end
      period = period.extend_to_weeks
      @period = session[:planning_period] = period
    end

    def default_period
      Period.next_n_months(3)
    end

    def authorize_action
      authorize!(:read, Planning)
    end

  end
end
