# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module Invoicing
  module SmallInvoice
    module Entity
      class Position < Base
        def to_hash
          {
            type: constant(:position_type_id),
            number: nil,
            name: entry.name,
            description: nil,
            cost: post.offered_rate.try(:round, 2),
            unit: constant(:unit_id),
            amount: entry.total_hours.round(2),
            vat: Settings.defaults.vat
          }
        end

        private

        def post
          entry.accounting_post
        end
      end
    end
  end
end
