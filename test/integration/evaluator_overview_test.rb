# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'

# Smoke test for the generic evaluator/_category partial, shared by (almost) every
# evaluation type. It isn't actually rendered by EvaluatorControllerTest, which only
# asserts the chosen template without rendering it.
class EvaluatorOverviewTest < ActionDispatch::IntegrationTest
  fixtures :all

  setup { login }

  %w[clients departments employees].each do |evaluation|
    test "#{evaluation} overview renders without error" do
      visit(evaluator_path(evaluation:))

      assert_selector('table#evaluation thead th', minimum: 1)
    end
  end

  test 'only the employees division header is sortable' do
    visit(evaluator_path(evaluation: 'clients'))

    assert_no_selector('table#evaluation thead th a')

    visit(evaluator_path(evaluation: 'employees'))

    assert_selector('table#evaluation thead th a', text: 'Member')
  end

  # Regression test: sorting by a Ruby-computed column used to crash with SystemStackError.
  %w[overtime vacations period_hours].each do |sort_column|
    test "employees sorted by #{sort_column} renders without error" do
      visit(evaluator_path(evaluation: 'employees', department_id: 0, member_coach_id: 0,
                           sort: sort_column, sort_dir: 'asc'))

      assert_selector('table#evaluation thead th', minimum: 1)
    end
  end

  private

  def login
    login_as(:mark)
  end
end
