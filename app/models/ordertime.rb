# encoding: utf-8
# == Schema Information
#
# Table name: worktimes
#
#  id              :integer          not null, primary key
#  project_id      :integer
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
#

class Ordertime < Worktime

  validate :validate_accounting_post
  validate :protect_booked, on: :update
  validate :validate_by_project

  before_destroy :protect_booked

  def self.valid_attributes
    super + [:account, :account_id, :description, :billable, :booked]
  end

  def self.account_label
    'Projekt'
  end

  def account
    work_item
  end

  def account_id
    work_item_id
  end

  def account_id=(value)
    self.work_item_id = value
  end

  def template(newWorktime = nil)
    newWorktime = super newWorktime
    newWorktime
  end

  ########### validation helpers ###########

  def validate_by_project
    work_item.accounting_post.validate_worktime(self) if work_item && work_item.accounting_post
  end

  def validate_accounting_post
    errors.add(:accounting_post_id, 'Der Auftrag hat keine Buchungsposition.') if work_item && !work_item.accounting_post
  end

  def protect_booked
    previous = Ordertime.find(id)
    if previous.booked && booked
      errors.add(:base, 'Verbuchte Arbeitszeiten können nicht verändert werden')
      return false
    end
  end

end
