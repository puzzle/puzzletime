# frozen_string_literal: true

#  Copyright (c) 2006-2025, Puzzle ITC AG. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'

class EvaluatorHelperTest < ActionView::TestCase
  include UtilityHelper
  include CrudTestHelper
  include FormatHelper

  setup :reset_db, :setup_db, :create_test_data
  teardown :reset_db

  test 'build custom detail label without period parameters' do
    employee = Employee.find_by(id: 1)
    label = {
      label: 'Meine Spesen',
      resource: employee,
      child_resource: :expenses,
      include_period_labels: false
    }
    expected_link = '<a href="/employees/1/expenses">Meine Spesen</a>'

    assert_equal(expected_link, build_detail_label_custom(label))
  end

  test 'build custom detail label with period parameters' do
    employee = Employee.find_by(id: 1)
    period = Period.new(Date.new(2025, 12, 1), Date.new(2025, 12, 31))
    label = {
      label: 'Meine Spesen',
      resource: employee,
      child_resource: :expenses,
      include_period_labels: true
    }
    expected_link = '<a href="/employees/1/expenses?end_date=2025-12-31&amp;start_date=2025-12-01">Meine Spesen</a>'

    assert_equal(expected_link, build_detail_label_custom(label, period))
  end
end
