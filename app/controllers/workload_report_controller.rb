# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

class WorkloadReportController < ApplicationController
  include DryCrud::Rememberable
  self.remember_params = %w[department_id]

  before_action :authorize_class

  attr_reader :period, :department

  def index
    set_period
    set_department
    @report = Reports::Workload.new(period, department, params)
    set_filter_values
    respond_to do |format|
      format.html
      format.js
    end
  end

  private

  def set_filter_values
    @departments = Department.having_employees.list
  end

  def set_department
    @department = Department.where(id: params[:department_id]).first
  end

  # rubocop:disable Naming/MemoizedInstanceVariableName
  def set_period
    super
    @period ||= default_period
  end
  # rubocop:enable Naming/MemoizedInstanceVariableName

  def default_period
    month = Time.zone.today.last_month
    Period.new(month.beginning_of_month, month.end_of_month)
  end

  def authorize_class
    authorize!(:read, Worktime)
  end
end
