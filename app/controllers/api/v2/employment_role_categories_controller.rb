# frozen_string_literal: true

#  Copyright (c) 2006-2026, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module Api
  module V2
    # Serves EmploymentRoleCategoryResource; the actions come from ResourceController.
    class EmploymentRoleCategoriesController < ResourceController
      # `dependent: :restrict_with_exception` of the model: still referenced.
      register_exception ActiveRecord::DeleteRestrictionError, status: 409, detail: :exception
    end
  end
end
