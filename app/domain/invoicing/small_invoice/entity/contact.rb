#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module Invoicing
  module SmallInvoice
    module Entity
      class Contact < Base
        def to_hash
          with_id(surname: entry.lastname,
                  name: entry.firstname,
                  email: entry.email,
                  phone: entry.phone,
                  gender: constant(:gender_id))
        end
      end
    end
  end
end
