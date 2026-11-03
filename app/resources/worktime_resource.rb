# frozen_string_literal: true

#  Copyright (c) 2006-2026, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# What Ordertime and Absencetime (two STI types of the `worktimes` table, one resource each) have in common, after
# WorktimesController: management sees and books for everyone, everybody else only their own rows. `Worktime` itself is
# never exposed; each subclass names its STI model, which scopes the rows to its `type`.
class WorktimeResource < ApplicationResource
  self.abstract_class = true

  TIMES = %i[from_start_time to_end_time].freeze

  attribute :work_date, :date
  attribute :hours, :hours, filterable: false
  attribute :description, :string
  attribute :employee_id, :integer, writable: :management?

  # Times are written as "14:00", "1400", "14.5", ... (parsed by the model) and read as "HH:MM".
  TIMES.each do |time|
    attribute time, :string, filterable: false, sortable: false do
      @object[time]&.strftime('%H:%M')
    end
  end

  def base_scope
    own_or_all(model.all)
  end

  # Without an employee the entry is the current user's (WorktimesController#build_entry); hours entered without
  # times must not be recomputed from stale times.
  before_attributes only: [:create] do |attributes|
    attributes[:employee_id] ||= context.current_user.id
  end

  before_attributes do |attributes|
    TIMES.each { |time| attributes[time] = nil } if attributes.key?(:hours) && TIMES.none? { |t| attributes.key?(t) }
  end

  after_destroy do |entry|
    EmployeeMailer.worktime_deleted_mail(entry, context.current_user).deliver_now if entry.employee != context.current_user
  end

  # The check WorktimesController runs as a before_save callback. An error added here fails the request (422);
  # saving is skipped.
  def save(entry, meta = nil)
    check_worktimes_committed(entry)
    entry.errors.any? ? entry : super
  end

  private

  # Employees can't touch their own committed worktimes, except as order responsible.
  def check_worktimes_committed(entry)
    user = context.current_user
    return if order_responsible?(entry, user) || entry.employee_id != user.id || !entry.worktimes_committed?

    entry.errors.add(:work_date, "Die Zeiten bis und mit #{I18n.l(user.committed_worktimes_at, format: :month)} " \
                                 'wurden freigegeben und können nicht mehr bearbeitet werden.')
  end

  def order_responsible?(_entry, _user)
    false
  end
end
