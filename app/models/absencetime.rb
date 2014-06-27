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
#


class Absencetime < Worktime

  validates :absence, presence: true

  attr_accessor :duration # used for multiabsence and not persisted

  def account
    absence
  end

  def account_id
    absence_id
  end

  def account_id=(value)
    self.absence_id = value
  end

  def absence?
    true
  end

  def self.account_label
    'Absenz'
  end

  def self.label
    'Absenz'
  end

  def self.valid_attributes
    super + [:account, :account_id, :description]
  end

  def billable
    false
  end

end
