# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module Plannings
  class CompanyOverview
    attr_reader :period, :boards

    # sort: { key: 'free' | 'name' | 'week', dir: 'asc' | 'desc', week: Monday of the week for key 'week' }
    def initialize(period, employee_ids: nil, department_id: nil, member_coach_id: nil, include_provisional: true,
                   sort: {})
      @period = period
      @employee_ids = employee_ids
      @department_id = department_id
      @member_coach_id = member_coach_id
      @include_provisional = include_provisional
      @boards = sort_boards(create_boards, **sort)
    end

    def weekly_planned_percent(date)
      @weekly_planned_percent ||= {}
      @weekly_planned_percent[date] ||= boards.sum { |board| board.weekly_planned_percent(date) }
    end

    def weekly_employment_percent(date)
      @weekly_employment_percent ||= {}
      @weekly_employment_percent[date] ||=
        boards.sum { |board| board.weekly_employment_percent(date).to_f }
    end

    private

    def create_boards
      conditions = { id: @employee_ids, department_id: @department_id, member_coach_id: @member_coach_id }.compact
      employees = Employee.employed_ones(period).list.where(conditions)
      employees.map { |e| Plannings::EmployeeBoard.new(e, period, include_provisional: @include_provisional) }
    end

    # ties are always broken by name ascending
    def sort_boards(boards, key: 'free', dir: 'desc', week: nil)
      desc = dir == 'desc'
      case key
      when 'name'
        sorted = boards.sort_by { |b| name_key(b) }
        desc ? sorted.reverse : sorted
      when 'week'
        boards.sort_by { |b| [desc ? -week_free(b, week) : week_free(b, week), name_key(b)] }
      else
        boards.sort_by { |b| [desc ? -b.overall_free_capacity : b.overall_free_capacity, name_key(b)] }
      end
    end

    def name_key(board)
      [board.employee.lastname.to_s, board.employee.firstname.to_s]
    end

    def week_free(board, date)
      board.weekly_employment_percent(date).to_f - board.weekly_planned_percent(date).to_f
    end
  end
end
