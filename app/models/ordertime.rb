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
#  booked          :boolean          default(FALSE)
#  type            :string(255)
#  ticket          :string(255)
#  work_item_id    :integer
#  invoice_id      :integer
#

class Ordertime < Worktime

  alias_attribute :account, :work_item
  alias_attribute :account_id, :work_item_id

  validates_by_schema
  validates :work_item, presence: true
  validate :validate_accounting_post
  validate :protect_booked, on: :update
  validate :validate_by_work_item

  before_destroy :protect_booked

  def self.valid_attributes
    super + [:account, :account_id, :description, :billable, :booked]
  end

  def self.account_label
    'Position'
  end

  def account_id=(value)
    self.work_item_id = value
  end

  def order
    work_item.accounting_post.order
  end

  def amount
    hours * (work_item.accounting_post.offered_rate || 0)
  end

  def template(newWorktime = nil)
    newWorktime = super newWorktime
    newWorktime
  end

  ########### validation helpers ###########

  def validate_by_work_item
    work_item.accounting_post.validate_worktime(self) if work_item && work_item.accounting_post
  end

  def validate_accounting_post
    errors.add(:accounting_post_id, 'Der Auftrag hat keine Buchungsposition.') if work_item && !work_item.accounting_post
  end

  def protect_booked
    previous = Ordertime.find(id)
    if previous.booked && booked
      errors.add(:base, 'Verbuchte Arbeitszeiten können nicht verändert werden')
      false
    end
  end

end
