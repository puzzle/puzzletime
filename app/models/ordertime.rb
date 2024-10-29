# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# {{{
# == Schema Information
#
# Table name: worktimes
#
#  id                :integer          not null, primary key
#  billable          :boolean          default(TRUE)
#  description       :text
#  from_start_time   :time
#  hours             :float
#  meal_compensation :boolean          default(FALSE), not null
#  report_type       :string(255)      not null
#  ticket            :string(255)
#  to_end_time       :time
#  type              :string(255)
#  work_date         :date             not null
#  absence_id        :integer
#  employee_id       :integer
#  invoice_id        :integer
#  work_item_id      :integer
#
# Indexes
#
#  index_worktimes_on_invoice_id  (invoice_id)
#  worktimes_absences             (absence_id,employee_id,work_date)
#  worktimes_employees            (employee_id,work_date)
#  worktimes_work_items           (work_item_id,employee_id,work_date)
#
# Foreign Keys
#
#  fk_times_absences   (absence_id => absences.id) ON DELETE => cascade
#  fk_times_employees  (employee_id => employees.id) ON DELETE => cascade
#
# }}}

class Ordertime < Worktime
  self.account_label = 'Position'

  alias account work_item
  alias_attribute :account_id, :work_item_id

  validates_by_schema
  validates :work_item, presence: true
  validate :validate_accounting_post
  validate :validate_by_work_item
  validate :validate_work_item_open

  before_destroy :protect_work_item_closed

  def account_id=(value)
    self.work_item_id = value
  end

  def order
    work_item.accounting_post&.order
  end

  def offered_rate
    work_item.accounting_post.offered_rate || 0
  end

  def amount
    hours * offered_rate
  end

  def work_item_closed?
    work_item&.closed? ||
      (work_item_id_was && work_item_id_was != work_item_id &&
        WorkItem.exists?(id: work_item_id_was, closed: true))
  end

  def invoice_sent_or_paid?
    invoice && (invoice.sent? || invoice.paid? || invoice.partially_paid?)
  end

  private

  ########### validation helpers ###########

  def validate_by_work_item
    return unless work_item&.accounting_post

    work_item.accounting_post.validate_worktime(self)
  end

  def validate_accounting_post
    return unless work_item && !work_item.accounting_post

    errors.add(:work_item_id, 'Der Auftrag hat keine Buchungsposition.')
  end

  def validate_work_item_open
    return unless changed != %w[invoice_id] && work_item_closed?

    errors.add(:base, 'Auf geschlossene Aufträge und/oder Positionen kann nicht gebucht werden.')
  end

  def protect_work_item_closed
    if work_item_closed?
      errors.add(:base, 'Kann nicht gelöscht werden, da Auftrag und/oder Position geschlossen ist.')
      false
    else
      true
    end
  end
end
