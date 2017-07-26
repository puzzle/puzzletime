# encoding: utf-8

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


module Plannings
  class EmployeesController < BaseController

    self.search_columns = [:firstname, :lastname, :shortname]

    skip_authorize_resource

    before_action :load_possible_work_items, only: [:new, :show]

    private

    def list_entries
      super.employed_ones(Period.current_year)
    end

    def employee
      @employee ||= Employee.find(params[:id])
    end
    alias subject employee

    def build_board
      Plannings::EmployeeBoard.new(employee, @period)
    end

    def load_possible_work_items
      @possible_work_items ||= WorkItem
                               .joins(:accounting_post)
                               .where(closed: false)
                               .list
    end

    def params_with_restricted_items
      super.tap do |p|
        p[:items].select! do |hash|
          hash[:employee_id].to_i == employee.id
        end
      end
    end

    def plannings_to_destroy
      super.where(employee_id: employee.id)
    end

  end
end
