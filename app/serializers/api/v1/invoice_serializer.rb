# frozen_string_literal: true

#  Copyright (c) 2006-2026, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module Api
  module V1
    class InvoiceSerializer < ApiSerializer
      attributes :reference, :billing_date

      belongs_to :order

      annotate_attributes :reference, :billing_date
    end
  end
end
