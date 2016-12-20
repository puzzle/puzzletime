# encoding: utf-8
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
