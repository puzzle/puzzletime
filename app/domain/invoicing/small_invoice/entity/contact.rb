# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module Invoicing
  module SmallInvoice
    module Entity
      class Contact < Base
        ENDPOINT = 'contacts'

        def self.path(invoicing_key: nil)
          [ENDPOINT, invoicing_key].compact
        end

        def path
          self.class.path(invoicing_key: entry.invoicing_key)
        end

        def to_hash
          {
            number: entry.shortname,
            relation: ['CL'], # TODO: move to config/settings.yml:small_invoice/constants
            type: 'C', # TODO: move to config/settings.yml:small_invoice/constants
            name: entry.name,
            communication_language: constant(:language),
            ebill_account_id: entry.e_bill_account_key,

            main_address: Entity::Address.new(entry.billing_addresses.first).to_hash
          }
        end
      end
    end
  end
end
