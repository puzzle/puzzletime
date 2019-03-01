#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


module Api
  class EmployeesController < BaseController
    include Scopable
    # include DryCrudJsonapi
    # include DryCrudJsonapiSwagger
    #
    # swagger_param :index, :scope, type: 'string',
    #               enum: ['current'],
    #               description: <<~DESC
    #                             The query scope:
    #                               * current - only employees with a current employment
    #                            DESC


    self.search_columns = [:firstname, :lastname, :shortname]

    self.sort_mappings = { department_id: 'departments.name' }

    private

    def list_entries
      scope_entries_by(super.includes(:department, :current_employment).references(:department), :current)
    end
  end
end
