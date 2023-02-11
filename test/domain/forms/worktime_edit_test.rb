#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'

class Forms::WorktimeEditTest < ActiveSupport::TestCase
  test 'may add original' do
    assert edit.add_worktime(worktime)
    assert_equal [worktime], edit.worktimes
  end

  test 'may add new' do
    wt = Ordertime.new(hours: worktime.hours, work_date: worktime.work_date)
    edit.add_worktime(wt)
    assert_equal [], wt.errors.full_messages
    assert_equal [wt], edit.worktimes
  end

  test 'may not add additional hours' do
    wt = Ordertime.new(hours: worktime.hours * 2, work_date: worktime.work_date)
    edit.add_worktime(wt)
    assert wt.errors[:hours].present?
    assert_equal [], edit.worktimes
  end

  test 'may add different date' do
    wt = Ordertime.new(hours: worktime.hours, work_date: worktime.work_date + 10)
    edit.add_worktime(wt)
    assert wt.errors[:work_date].blank?
    assert_equal [wt], edit.worktimes
  end

  test 'is complete if sum hours equal original hours' do
    edit.add_worktime(Ordertime.new(hours: 0.5, work_date: worktime.work_date))
    assert !edit.complete?
    edit.add_worktime(Ordertime.new(hours: '0:20', work_date: worktime.work_date))
    assert !edit.complete?
    edit.add_worktime(Ordertime.new(hours: '0:10', work_date: worktime.work_date))
    assert edit.complete?
  end

  test 'worktime_template contains remaining hours' do
    edit.add_worktime(Ordertime.new(hours: 0.5, work_date: worktime.work_date))
    assert_equal 0.5, edit.worktime_template.hours
  end

  def edit
    @edit ||= Forms::WorktimeEdit.new(worktime)
  end

  def worktime
    worktimes(:wt_pz_allgemein)
  end
end
