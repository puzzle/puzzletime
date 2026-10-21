# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'

module Plannings
  class CompaniesControllerTest < ActionController::TestCase
    setup :login

    test 'GET #show renders values of all employed employees' do
      get :show

      assert_equal employees(:various_pedro, :next_year_pablo, :long_time_john),
                   assigns(:overview).boards.map(&:employee)
    end

    test 'GET #show filters by a selected custom list' do
      get :show, params: { custom_list_ids: [custom_lists(:list_a).id] }

      assert_equal employees(:various_pedro, :next_year_pablo),
                   assigns(:overview).boards.map(&:employee)
    end

    test 'GET #show combines employees from multiple selected custom lists' do
      get :show, params: { custom_list_ids: [custom_lists(:list_a).id, custom_lists(:list_b).id] }

      assert_equal employees(:various_pedro, :next_year_pablo, :long_time_john),
                   assigns(:overview).boards.map(&:employee)
    end

    test 'GET #show remembers the custom list selection in session' do
      get :show, params: { custom_list_ids: [custom_lists(:list_a).id] }
      get :show

      assert_equal employees(:various_pedro, :next_year_pablo),
                   assigns(:overview).boards.map(&:employee)
    end

    test 'GET #show clears a remembered selection when submitted empty' do
      get :show, params: { custom_list_ids: [custom_lists(:list_a).id] }
      get :show, params: { custom_list_ids: [''] }

      assert_equal employees(:various_pedro, :next_year_pablo, :long_time_john),
                   assigns(:overview).boards.map(&:employee)
    end

    test 'GET #show counts only definitive plannings unless provisional ones are included' do
      monday = Date.current.beginning_of_week + 7
      create_planning(monday, definitive: true)
      create_planning(monday + 1, definitive: false)

      get :show
      without_provisional = board_for(employees(:long_time_john)).weekly_planned_percent(monday)
      get :show, params: { include_provisional: '1' }
      with_provisional = board_for(employees(:long_time_john)).weekly_planned_percent(monday)

      assert_in_delta 10.0, with_provisional - without_provisional
    end

    test 'GET #show filters by department' do
      get :show, params: { department_id: departments(:devone).id }

      assert_equal [employees(:long_time_john)], assigns(:overview).boards.map(&:employee)
    end

    test 'GET #show filters by member coach' do
      employees(:next_year_pablo).update!(member_coach: employees(:mark))
      get :show, params: { member_coach_id: employees(:mark).id }

      assert_equal [employees(:next_year_pablo)], assigns(:overview).boards.map(&:employee)
    end

    test 'GET #show combines department with custom list filter' do
      get :show, params: { department_id: departments(:devone).id, custom_list_ids: [custom_lists(:list_a).id] }

      assert_empty assigns(:overview).boards
    end

    test 'GET #show remembers department, member coach and provisional filters in session' do
      employees(:long_time_john).update!(member_coach: employees(:mark))
      get :show, params: { department_id: departments(:devone).id, member_coach_id: employees(:mark).id,
                           include_provisional: '1' }
      get :show

      assert_equal [employees(:long_time_john)], assigns(:overview).boards.map(&:employee)
      assert assigns(:filters)[:include_provisional]

      get :show, params: { include_provisional: '0' }

      assert_not assigns(:filters)[:include_provisional]
    end

    test 'GET #show sorts by name ascending and descending' do
      get :show, params: { sort: 'name', sort_dir: 'asc' }
      names = assigns(:overview).boards.map(&:employee)

      assert_equal names.sort_by { |e| [e.lastname, e.firstname] }, names

      get :show, params: { sort: 'name', sort_dir: 'desc' }

      assert_equal names.reverse, assigns(:overview).boards.map(&:employee)
    end

    test 'GET #show sorts by free capacity of the given week, most free first' do
      monday = Date.current.beginning_of_week + 7
      create_planning(monday, definitive: true)

      get :show, params: { sort: 'week', sort_dir: 'desc', sort_week: monday.iso8601 }
      boards = assigns(:overview).boards
      frees = boards.map { |b| b.weekly_employment_percent(monday).to_f - b.weekly_planned_percent(monday).to_f }

      assert_equal 'week', assigns(:sort)[:key]
      assert_equal frees.sort.reverse, frees
    end

    test 'GET #show falls back to free capacity for a week outside the period' do
      get :show, params: { sort: 'week', sort_dir: 'desc', sort_week: '1999-01-04' }

      assert_equal 'free', assigns(:sort)[:key]
    end

    test 'GET #show breaks ties by name ascending' do
      get :show, params: { sort: 'free', sort_dir: 'desc' }
      boards = assigns(:overview).boards

      boards.each_cons(2) do |a, b|
        assert_operator a.overall_free_capacity, :>=, b.overall_free_capacity
        next unless a.overall_free_capacity == b.overall_free_capacity

        key_a = [a.employee.lastname, a.employee.firstname]
        key_b = [b.employee.lastname, b.employee.firstname]

        assert_operator key_a <=> key_b, :<=, 0
      end
    end

    test 'GET #show remembers the sort in session and ignores provisional toggle under name sort' do
      get :show, params: { sort: 'name', sort_dir: 'desc' }
      names = assigns(:overview).boards.map(&:employee)
      get :show, params: { include_provisional: '1' }

      assert_equal 'name', assigns(:sort)[:key]
      assert_equal 'desc', assigns(:sort)[:dir]
      assert_equal names, assigns(:overview).boards.map(&:employee)
    end

    private

    def create_planning(date, definitive:)
      Planning.create!(employee: employees(:long_time_john), work_item: work_items(:puzzletime),
                       date:, percent: 50, definitive:)
    end

    def board_for(employee)
      assigns(:overview).boards.find { |board| board.employee == employee }
    end
  end
end
