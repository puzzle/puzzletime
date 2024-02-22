# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module Invoicing
  module SmallInvoice
    module Entity
      class Address < Base
        def to_hash
          street, street2 = entry.supplement? ? [entry.supplement, entry.street] : [entry.street, nil]
          with_id(street:,
                  street2:,
                  postcode: entry.zip_code,
                  city: entry.town,
                  country: entry.country)
        end
      end
    end
  end
end
