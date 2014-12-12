# encoding: utf-8

class OrderServicesController < ApplicationController

  include Filterable
  include DryCrud::Rememberable
  include Concerns::WorktimesReport

  self.remember_params = %w(employee_id work_item_id billable)

  before_action :order
  before_action :authorize_class
  before_filter :handle_remember_params, only: [:show]
  before_action :set_evaluation, only: [:compose_report, :report]
  before_action :set_filter_values, only: [:show, :export_worktimes_csv]

  def show
    @worktimes = list_worktimes
  end

  def export_worktimes_csv
    @worktimes = list_worktimes
    send_worktimes_csv(@worktimes, worktimes_csv_filename)
  end

  def report
    conditions = {}
    conditions[:worktimes] = { billable: params[:billable] } if params[:billable].present?
    conditions[:employee_id] = params[:employee_id] if params[:employee_id].present?
    render_report(conditions)
  end

  private

  def list_worktimes
    entries = order.worktimes.
                    includes(:employee, :work_item).
                    order(:work_date).
                    in_period(@period)
    filter_entries_by(entries, :employee_id, :work_item_id, :billable)
  end

  def worktimes_csv_filename
    order_shortnames = order.work_item.path_shortnames
    accounting_post_shortnames = WorkItem.find(params[:work_item_id]).path_shortnames if params[:work_item_id].present?
    employee_shortname = Employee.find(params[:employee_id]).shortname if params[:employee_id].present?
    billable = "billable_#{params[:billable]}" if params[:billable].present?
    ['puzzletime', accounting_post_shortnames || order_shortnames, employee_shortname, billable, '.csv'].compact.join('-')
  end

  def order
    @order ||= Order.find(params[:order_id])
  end

  def set_filter_values
    set_period
    @employees = Employee.where(id: order.worktimes.select(:employee_id)).list
    @accounting_posts = order.work_item.self_and_descendants.leaves.list
  end

  def set_period
    if params[:period].present?
      @period = Period.parse(params.delete(:period))
    else
      @period = Period.retrieve(params[:start_date].presence,
                                params[:end_date].presence)
    end
    fail ArgumentError, 'Start Datum nach End Datum' if @period.negative?
  rescue ArgumentError => ex
    # from Period.retrieve or if period.negative?
    flash.now[:alert] = "Ungültige Zeitspanne: #{ex}"
    @period = Period.new(nil, nil)

    params.delete(:start_date)
    params.delete(:end_date)
  end

  def set_evaluation
    work_item_id = params[:work_item_id].present? ? params[:work_item_id] : order.work_item_id
    @evaluation = WorkItemEmployeesEval.new(work_item_id)
    if params[:start_date].present? && params[:start_date] != '0'
      @period = Period.retrieve(params[:start_date], params[:end_date])
    end
  end

  def authorize_class
    authorize!(:services, order)
  end

end