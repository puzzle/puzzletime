# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module Invoicing
  module SmallInvoice
    module Entity
      class FlatratePosition < Base
        def to_hash
          {
            type: constant(:position_type_id),
            number: nil,
            name: "#{post.name} - #{entry.flatrate.name}",
            description: nil,
            cost: entry.flatrate.amount.try(:round, 2),
            unit: entry.flatrate.unit,
            amount: entry.quantity,
            vat: Settings.defaults.vat
          }
        end

        private

        def post
          entry.flatrate.accounting_post
        end
      end
    end
  end
end
