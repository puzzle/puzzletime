# encoding: utf-8

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


require 'test_helper'

class EditWorktimesCommitTest < ActionDispatch::IntegrationTest

  test 'change worktimes commit date updates label' do
    Fabricate(:ordertime, employee: employees(:long_time_john), work_item: work_items(:allgemein))
    login
    current_month = I18n.l(Time.zone.today.at_end_of_month, format: :month)
    label = find("#committed_worktimes_at_#{employees(:long_time_john).id}")
    assert label.has_selector?('.icon-square.red')

    find("a[data-element='#committed_worktimes_at_#{employees(:long_time_john).id}']").click
    assert_selector('.modal-body #employee_committed_worktimes_at')
    select(current_month, from: 'employee_committed_worktimes_at')
    click_button 'Speichern'

    assert label.has_content?(current_month)
    assert label.has_selector?('.icon-disk.green')
  end


  def login
    login_as(:mark, '/evaluator/employees')
  end

end
