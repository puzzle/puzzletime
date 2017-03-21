# encoding: utf-8

class RevenueReportsController < ApplicationController

  before_action :authorize_class
  before_action :set_period

  REPORT_TYPES = [
    Reports::Revenue::Department,
    Reports::Revenue::PortfolioItem,
    Reports::Revenue::Service,
    Reports::Revenue::Sector
  ].freeze

  def index
    @report_types = REPORT_TYPES
    @report = report_type.new(@period, params)
    respond_to do |format|
      format.html {}
    end
  end

  private

  def report_type
    grouping = params[:grouping].present? ? params[:grouping] : 'Department'
    REPORT_TYPES.find { |r| r.grouping_name == grouping }
  end

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