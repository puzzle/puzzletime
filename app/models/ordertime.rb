# encoding: utf-8

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

  alias_attribute :account, :work_item
  alias_attribute :account_id, :work_item_id

  validates_by_schema
  validates :work_item, presence: true
  validate :validate_accounting_post
  validate :validate_by_work_item
  validate :validate_work_item_open, unless: :only_invoice_id_changed?
  validate :validate_worktimes_committed, unless: :only_invoice_id_changed?

  before_destroy :protect_work_item_closed
  before_destroy :protect_committed_worktimes


  def account_id=(value)
    self.work_item_id = value
  end

  def order
    work_item.accounting_post.order
  end

  def amount
    hours * (work_item.accounting_post.offered_rate || 0)
  end

  def work_item_closed?
    (work_item && work_item.closed?) ||
    (work_item_id_was && work_item_id_was != work_item_id &&
      WorkItem.where(id: work_item_id_was, closed: true).exists?)
  end

  def worktimes_committed?
    committed_at = employee.committed_worktimes_at

    committed_at &&
    ((work_date && committed_at >= work_date) ||
     (work_date_was && committed_at >= work_date_was))
  end

  private

  ########### validation helpers ###########

  def only_invoice_id_changed?
    changes.keys == %w(invoice_id)
  end

  def validate_by_work_item
    if work_item && work_item.accounting_post
      work_item.accounting_post.validate_worktime(self)
    end
  end

  def validate_accounting_post
    if work_item && !work_item.accounting_post
      errors.add(:work_item_id, 'Der Auftrag hat keine Buchungsposition.')
    end
  end

  def validate_work_item_open
    if work_item_closed?
      errors.add(:base, 'Auf geschlossene Aufträge und/oder Positionen kann nicht gebucht werden.')
    end
  end

  def validate_worktimes_committed
    if worktimes_committed?
      date = I18n.l(employee.committed_worktimes_at, format: :month)
      errors.add(:work_date, "Die Zeiten bis und mit #{date} wurden freigegeben " \
                             'und können nicht mehr bearbeitet werden.')
    end
  end

  def protect_committed_worktimes
    if worktimes_committed?
      date = I18n.l(employee.committed_worktimes_at, format: :month)
      errors.add(:base, "Die Zeiten bis und mit #{date} wurden freigegeben " \
                        'und können nicht gelöscht werden.')
      false
    else
      true
    end
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
