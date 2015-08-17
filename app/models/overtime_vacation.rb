# encoding: utf-8
# == Schema Information
#
# Table name: overtime_vacations
#
#  id            :integer          not null, primary key
#  hours         :float            not null
#  employee_id   :integer          not null
#  transfer_date :date             not null
#


class OvertimeVacation < ActiveRecord::Base

  belongs_to :employee

  validates_by_schema
  validates :hours, inclusion: { in: 0.001...999_999, message: 'Die Stunden müssen positiv sein' }
  validates :transfer_date, timeliness: { date: true, allow_blank: true }

  scope :list, -> { order('transfer_date DESC') }

  def to_s
    "von #{hours} Stunden#{" am #{I18n.l(transfer_date)}" if transfer_date}"
  end

end
