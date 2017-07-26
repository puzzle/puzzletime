# encoding: utf-8

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


class MultiWorktimesController < ApplicationController
  skip_authorization_check

  before_action :order
  before_action :authorize_class

  def edit
    if params[:worktime_ids].present?
      worktimes
      load_field_presets
      render 'edit'
    else
      redirect_to index_path, alert: 'Bitte wählen sie mindestens einen Eintrag aus.'
    end
  end

  def update
    if changed_attrs.present?
      if update_worktimes
        redirect_to index_path, notice: "#{worktimes.size} Zeiten wurden aktualisiert."
      else
        edit
      end
    else
      redirect_to index_path, notice: 'Es wurden keine Änderungen vorgenommen.'
    end
  end

  private

  def order
    @order ||= Order.find(params[:order_id])
  end

  def worktimes
    @worktimes ||=
      Worktime
      .where(id: params[:worktime_ids])
      .includes([:employee, :work_item, :invoice])
  end

  def load_field_presets
    work_item_id = params[:work_item_id] || multi_worktime_value(:work_item_id)
    @work_item = WorkItem.find(work_item_id) if work_item_id
    @ticket = params[:ticket] || multi_worktime_value(:ticket)
    @billable = params[:billable] || multi_worktime_value(:billable)
  end

  def multi_worktime_value(attr)
    values = worktimes.collect(&attr).uniq
    values.size == 1 ? values.first : nil
  end

  def changed_attrs
    @changed_attrs ||= %w(work_item_id ticket billable).select do |attr|
      ActiveRecord::Type::Boolean.new.deserialize(params["change_#{attr}"])
    end
  end

  def update_worktimes
    Worktime.transaction do
      worktimes.includes(work_item: :accounting_post).each do |t|
        # update each individually to run validations
        t.update!(params.permit(*changed_attrs))
      end
    end
    true
  rescue ActiveRecord::RecordInvalid => e
    @errors = e.record.errors
    false
  end

  def index_path
    order_order_services_path(order, returning: true)
  end

  def authorize_class
    worktimes.each do |worktime|
      authorize!(:edit, worktime)
    end
  end
end
