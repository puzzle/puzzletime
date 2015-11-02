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
  validate :validate_work_item_open
  validate :validate_worktimes_committed

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

  ########### validation helpers ###########

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
    work_item_was = work_item_id_was && WorkItem.find(work_item_id_was)
    if (work_item && work_item.closed?) ||
       (work_item_was && work_item_was.closed?)
      errors.add(:base, 'Auf geschlossene Aufträge und/oder Positionen kann nicht gebucht werden.')
    end
  end

  def validate_worktimes_committed
    committed_at = employee.committed_worktimes_at
    return if committed_at.nil?

    if committed_at >= work_date || (work_date_was &&  committed_at >= work_date_was)
      date = I18n.l(committed_at, format: :month)
      errors.add(:work_date, "Die Zeiten bis und mit #{date} wurden freigegeben "  \
                             'und können nicht mehr bearbeitet werden.')
    end
  end

  def protect_committed_worktimes
    if employee.committed_worktimes_at && employee.committed_worktimes_at >= work_date
      date = I18n.l(employee.committed_worktimes_at, format: :month)
      errors.add(:base, "Die Zeiten bis und mit #{date} wurden freigegeben "  \
                        'und können nicht gelöscht werden.')
      false
    else
      true
    end
  end

  def protect_work_item_closed
    if work_item.try(:closed?)
      errors.add(:base, 'Kann nicht gelöscht werden, da Auftrag und/oder Position geschlossen ist.')
      false
    else
      true
    end
  end
end
