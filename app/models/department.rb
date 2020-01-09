#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


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
  has_many :employee_worktimes, through: :employees, source: :worktimes

  validates_by_schema

  protect_if :worktimes, 'Dieser Eintrag kann nicht gelöscht werden, da ihm noch Arbeitszeiten zugeordnet sind'
  protect_if :orders, 'Dieser Eintrag kann nicht gelöscht werden, da ihm noch Aufträge zugeordnet sind'

  scope :list, -> { order('name') }
  scope :having_employees, -> { where('EXISTS (SELECT 1 FROM employees WHERE department_id = departments.id)') }


  def to_s
    name
  end

  def worktimes
    Worktime.
      joins(:work_item).
      joins('INNER JOIN orders ON orders.work_item_id = ANY (work_items.path_ids)').
      where(orders: { department_id: id })
  end

  def plannings
    Planning.
      joins(:work_item).
      joins('INNER JOIN orders ON orders.work_item_id = ANY (work_items.path_ids)').
      where(orders: { department_id: id })
  end

  ##### interface methods for Evaluatable #####

  def self.worktimes
    Worktime.all
  end

  def self.plannings
    Planning.all
  end

end
