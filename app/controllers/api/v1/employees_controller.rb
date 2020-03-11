# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module Api
  module V1
    class EmployeesController < JsonapiController
      include Scopable

      annotate_param :index, :scope, type: 'string',
                                     enum: ['current'],
                                     description: <<~DESC
                                       The query scope:
                                       * current - only employees with a current employment
                                     DESC

      def list_entries
        entries = super.includes(:department,
                                 current_employment: {
                                   employment_roles_employments: :employment_role
                                 })
        scoped(entries, :current)
      end
    end
  end
end
