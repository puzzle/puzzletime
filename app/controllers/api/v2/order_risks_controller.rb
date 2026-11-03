# frozen_string_literal: true

#  Copyright (c) 2006-2026, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module Api
  module V2
    # Serves OrderRiskResource; the actions come from ResourceController. Saving or deleting an uncertainty re-saves its
    # order, which may be invalid.
    class OrderRisksController < ResourceController
      register_exception ActiveRecord::RecordInvalid, status: 422, message: true
    end
  end
end
