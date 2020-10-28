#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module Invoicing
  module SmallInvoice
    module Entity
      class Address < Base
        ENDPOINT = 'addresses'.freeze

        def self.path(client, invoicing_key: nil)
          [*Entity::Contact.new(client).path, ENDPOINT, invoicing_key].compact if client.persisted?
        end

        def path
          self.class.path(entry.client, invoicing_key: entry.invoicing_key) if persisted?
        end

        def to_hash
          street, street2 = entry.supplement? ? [entry.supplement, entry.street] : [entry.street, nil]
          with_id(street: street,
                  street2: street2,
                  postcode: entry.zip_code,
                  city: entry.town,
                  country: entry.country)
        end
      end
    end
  end
end
