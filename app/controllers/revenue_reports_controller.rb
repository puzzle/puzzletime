# encoding: utf-8

class RevenueReportsController < ApplicationController

  before_action :authorize_class
  before_action :set_period

  def index
    @report = Reports::Revenue.new(@period, params)
    respond_to do |format|
      format.html {}
      # format.csv {}
    end
  end

  private

  def set_period
    super
    if @period.nil? || @period.start_date.nil? || @period.end_date.nil?
      @period = default_period
    end
  end

  def default_period
    Period.parse('b')
  end

  def authorize_class
    authorize!(:revenue_reports, Department)
  end

end
