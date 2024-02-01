#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# == Schema Information
#
# Table name: worktimes
#
#  id              :integer          not null, primary key
#  absence_id      :integer
#  employee_id     :integer
#  report_type     :string(255)      not null
#  work_date       :date             not null
#  hours           :float
#  from_start_time :time
#  to_end_time     :time
#  description     :text
#  billable        :boolean          default(TRUE)
#  type            :string(255)
#  ticket          :string(255)
#  work_item_id    :integer
#  invoice_id      :integer
#

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
    work_item.accounting_post && work_item.accounting_post.order
  end

  def amount
    hours * (work_item.accounting_post.offered_rate || 0)
  end

  def work_item_closed?
    (work_item && work_item.closed?) ||
      (work_item_id_was && work_item_id_was != work_item_id &&
        WorkItem.where(id: work_item_id_was, closed: true).exists?)
  end

  def invoice_sent_or_paid?
    invoice && (invoice.sent? || invoice.paid? || invoice.partially_paid?)
  end

  private

  ########### validation helpers ###########

  def validate_by_work_item
    return unless work_item && work_item.accounting_post

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
