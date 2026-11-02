# frozen_string_literal: true

#  Copyright (c) 2006-2026, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# Mirrors WorktimesController/OrdertimesController: management sees and books for everyone, everybody else only
# their own rows.
class OrdertimeResource < ApplicationResource
  model Ordertime

  TIMES = %i[from_start_time to_end_time].freeze

  attribute :work_item_id, :integer
  attribute :work_date, :date
  attribute :hours, :hours, filterable: false
  attribute :description, :string
  attribute :internal_description, :string
  attribute :billable, :boolean
  attribute :ticket, :string
  attribute :meal_compensation, :boolean
  attribute :employee_id, :integer, writable: :management?
  attribute :invoice_id, :integer, writable: false

  # Times are written as "14:00", "1400", "14.5", ... (parsed by the model) and read as "HH:MM".
  %i[from_start_time to_end_time].each do |time|
    attribute time, :string, filterable: false, sortable: false do
      @object[time]&.strftime('%H:%M')
    end
  end

  def base_scope
    user = context.current_user
    return Ordertime.none unless user.is_a?(Employee)

    user.management? ? Ordertime.all : Ordertime.where(employee_id: user.id)
  end

  def management?
    context.current_user.try(:management?)
  end

  # Without an employee the entry is the current user's (WorktimesController#build_entry); hours entered without
  # times must not be recomputed from stale times.
  before_attributes only: [:create] do |attributes|
    attributes[:employee_id] ||= context.current_user.id
  end

  before_attributes do |attributes|
    TIMES.each { |time| attributes[time] = nil } if attributes.key?(:hours) && TIMES.none? { |t| attributes.key?(t) }
  end

  after_destroy do |model|
    EmployeeMailer.worktime_deleted_mail(model, context.current_user).deliver_now if model.employee != context.current_user
  end

  # The checks WorktimesController runs as before_save callbacks. Errors added here fail the request (422);
  # saving is skipped.
  def save(model, meta = nil)
    check_accounting_post(model)
    check_worktimes_committed(model)
    model.errors.any? ? model : super
  end

  private

  def check_accounting_post(model)
    work_item = model.work_item
    return unless work_item && !work_item.accounting_post

    model.errors.add(:work_item_id, 'Der Auftrag hat keine Buchungsposition.')
  end

  # Employees can't touch their own committed worktimes, except as order responsible.
  def check_worktimes_committed(model)
    user = context.current_user
    return if model.order&.responsible_id == user.id || model.employee_id != user.id || !model.worktimes_committed?

    model.errors.add(:work_date, "Die Zeiten bis und mit #{I18n.l(user.committed_worktimes_at, format: :month)} " \
                                 'wurden freigegeben und können nicht mehr bearbeitet werden.')
  end
end
