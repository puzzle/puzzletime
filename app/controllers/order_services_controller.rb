# encoding: utf-8

class OrderServicesController < ApplicationController

  include Filterable
  include DryCrud::Rememberable
  include Concerns::WorktimesReport

  self.remember_params = %w(employee_id work_item_id billable)

  before_action :order
  before_action :authorize_class
  before_filter :handle_remember_params, only: [:show]
  before_action :set_filter_values, only: [:show, :export_worktimes_csv]

  def show
    @worktimes = list_worktimes
  end

  def export_worktimes_csv
    binding.pry
    send_worktimes_csv(list_worktimes, worktimes_csv_filename)
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
    accounting_post_shortnames =
        params[:work_item_id].present? ? WorkItem.find(params[:work_item_id]).path_shortnames : nil
    order_shortnames = order.work_item.path_shortnames
    [
        'puzzletime',
        accounting_post_shortnames || order_shortnames,
        Employee.find(params[:employee_id]).shortname,
        params[:billable].present? ? "billable_#{params[:billable]}" : nil,
        '.csv'
    ].compact.join('-')
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

  def authorize_class
    authorize!(:services, order)
  end

end