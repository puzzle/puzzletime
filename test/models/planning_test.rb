#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


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

require 'test_helper'

class PlanningTest < ActiveSupport::TestCase

  test 'is invalid for weekends' do
    (Date.new(2000, 1, 1)..Date.new(2000, 1, 2)).each do |date|
      assert Planning.new(employee_id: employee_id,
                          work_item_id: work_item_id,
                          date: date,
                          percent: 50,
                          definitive: true).invalid?
    end
  end

  test 'is valid for weekdays' do
    (Date.new(2000, 1, 3)..Date.new(2000, 1, 7)).each do |date|
      assert Planning.new(employee_id: employee_id,
                          work_item_id: work_item_id,
                          date: date,
                          percent: 50,
                          definitive: true).valid?
    end
  end

  private

  def employee_id
    employees(:pascal).id
  end

  def work_item_id
    work_items(:puzzletime).id
  end

end
