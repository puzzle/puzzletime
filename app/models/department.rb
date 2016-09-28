# encoding: utf-8

# == Schema Information
#
# Table name: departments
#
#  id        :integer          not null, primary key
#  name      :string(255)      not null
#  shortname :string(3)        not null
#
class Department < ActiveRecord::Base

  include Evaluatable

  has_many :orders
  has_many :employees, dependent: :nullify

  validates_by_schema

  protect_if :worktimes, 'Dieser Eintrag kann nicht gelöscht werden, da ihm noch Arbeitszeiten zugeordnet sind'
  protect_if :orders, 'Dieser Eintrag kann nicht gelöscht werden, da ihm noch Aufträge zugeordnet sind'

  scope :list, -> { order('name') }
  scope :having_employees, -> { where('EXISTS (SELECT 1 FROM employees WHERE department_id = departments.id)') }


  def to_s
    name
  end

  def worktimes
    Worktime.joins(:work_item).
      joins('INNER JOIN orders ON orders.work_item_id = ANY (work_items.path_ids)').
      where(orders: { department_id: id })
  end

  ##### interface methods for Evaluatable #####

  def self.worktimes
    Worktime.all
  end
end
