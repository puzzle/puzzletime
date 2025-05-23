# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

class RevenueReportsController < ApplicationController
  before_action :authorize_class
  before_action :set_period

  REPORT_TYPES = [
    Reports::Revenue::DepartmentOrder,
    Reports::Revenue::DepartmentMember,
    Reports::Revenue::PortfolioItem,
    Reports::Revenue::Service,
    Reports::Revenue::Sector
  ].freeze

  def index
    @report = report_type.new(@period, params)

    respond_to do |format|
      format.any
      format.csv do
        send_data(
          Reports::Revenue::Csv.new(@report).generate,
          filename: csv_filename,
          type: 'text/csv; charset=utf-8; header=present'
        )
      end
    end
  end

  private

  def csv_filename
    name   = 'revenue'
    period = @report&.period

    name += "_#{@report.grouping_name.underscore}" if @report&.grouping_name

    name += "_#{period.start_date.strftime('%Y-%m-%d')}" if period&.start_date

    if period&.end_date &&
       period&.end_date != period&.start_date
      name += "_#{period.end_date.strftime('%Y-%m-%d')}"
    end

    "#{name}.csv"
  end

  def report_type
    grouping = params[:grouping].presence
    REPORT_TYPES.find { |r| r.grouping_name == grouping } || REPORT_TYPES.first
  end

  def set_period
    super
    return unless @period.nil? || @period.start_date.nil? || @period.end_date.nil?

    @period = default_period
  end

  def default_period
    Period.parse('b')
  end

  def authorize_class
    authorize!(:revenue_reports, Department)
  end
end
