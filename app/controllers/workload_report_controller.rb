# encoding: utf-8

class WorkloadReportController < ApplicationController

  include DryCrud::Rememberable
  include WithPeriod

  self.remember_params = %w(start_date end_date department_id)

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

  def default_period
    month = Time.zone.today.last_month
    Period.new(month.beginning_of_month, month.end_of_month)
  end

  def authorize_class
    authorize!(:read, Worktime)
  end

end
