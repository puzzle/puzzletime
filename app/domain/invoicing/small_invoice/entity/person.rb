#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module Invoicing
  module SmallInvoice
    module Entity
      class Person < Base
        ENDPOINT = 'people'

        def self.path(client, invoicing_key: nil)
          [*Contact.new(client).path, ENDPOINT, invoicing_key].compact if client.persisted?
        end

        def path
          self.class.path(entry.client, invoicing_key: entry.invoicing_key) if persisted?
        end

        def to_hash
          with_id(surname: entry.lastname,
                  name: entry.firstname,
                  email: entry.email,
                  phone: entry.phone,
                  gender: 'F')
        end
      end
    end
  end
end