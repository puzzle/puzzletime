# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# {{{
# == Schema Information
#
# Table name: plannings
#
#  id           :integer          not null, primary key
#  date         :date             not null
#  definitive   :boolean          default(FALSE), not null
#  percent      :integer          not null
#  employee_id  :integer          not null
#  work_item_id :integer          not null
#
# Indexes
#
#  index_plannings_on_employee_id                            (employee_id)
#  index_plannings_on_employee_id_and_work_item_id_and_date  (employee_id,work_item_id,date) UNIQUE
#  index_plannings_on_work_item_id                           (work_item_id)
#
# }}}

require 'test_helper'

class PlanningTest < ActiveSupport::TestCase
  test 'is invalid for weekends' do
    (Date.new(2000, 1, 1)..Date.new(2000, 1, 2)).each do |date|
      assert_predicate Planning.new(employee_id:,
                                    work_item_id:,
                                    date:,
                                    percent: 50,
                                    definitive: true), :invalid?
    end
  end

  test 'is valid for weekdays' do
    (Date.new(2000, 1, 3)..Date.new(2000, 1, 7)).each do |date|
      assert_predicate Planning.new(employee_id:,
                                    work_item_id:,
                                    date:,
                                    percent: 50,
                                    definitive: true), :valid?
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
