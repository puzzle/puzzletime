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
  validate :date_must_be_weekday

  belongs_to :employee
  belongs_to :work_item # must be work item with accounting post

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

  def order
    @order ||=
      Order.joins('LEFT JOIN work_items ON ' \
                  'orders.work_item_id = ANY (work_items.path_ids)').
      find_by('work_items.id = ?', work_item_id)
  end

  private

  def date_must_be_weekday
    if date.saturday? || date.sunday?
      errors.add(:weekday, 'muss ein Werktag sein')
    end
  end

end
