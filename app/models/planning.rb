# encoding: utf-8
# == Schema Information
#
# Table name: plannings
#
#  id           :integer          not null, primary key
#  employee_id  :integer          not null
#  work_item_id :integer          not null
#  date         :date             not null
#  percent      :integer          not null
#  definitive   :boolean          default(FALSE), not null
#

class Planning < ActiveRecord::Base

  validates_by_schema

  belongs_to :employee
  belongs_to :work_item

  scope :in_period, (lambda do |period|
    if period
      where(period.where_condition('date'))
    else
      all
    end
  end)

  scope :list, -> { order(:date) }


  def to_s
    "#{percent}% auf #{work_item} am #{I18n.l(date)} für #{employee}"
  end

end
