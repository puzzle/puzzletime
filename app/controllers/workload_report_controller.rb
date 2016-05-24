# encoding: utf-8

class WorkloadReportController < ApplicationController

  include DryCrud::Rememberable

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

  def set_period
    @period = Period.retrieve(start_date.presence, end_date.presence)
    if @period.negative?
      flash.now[:alert] = 'Ungültige Zeitspanne: Start Datum nach End Datum'
      fail ArgumentError
    end
    @period
  rescue ArgumentError => _
    flash.now[:alert] ||= 'Ungültiges Datum'
    @period = Period.new(nil, nil)

    params.delete(:start_date)
    params.delete(:end_date)
    @period
  end

  def start_date
    params.has_key?(:start_date) ? params[:start_date] : Date.today.last_month.beginning_of_month
  end

  def end_date
    params.has_key?(:end_date) ? params[:end_date] : Date.today.last_month.end_of_month
  end

  def authorize_class
    authorize!(:read, Worktime)
  end

end
