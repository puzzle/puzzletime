#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


module Invoicing
  class Interface
    # Stores a new or an existing invoice with the given positions in the remote system.
    def save_invoice(_invoice, _positions)
    end

    # Fetches and updates the data for the given invoice from the remote system.
    # The invoice will be destroyed if the remote system deleted it.
    def sync_invoice(_invoice)
    end

    # Delete a given invoice in the remote system.
    def delete_invoice(_invoice)
    end

    # Sync all entities to the invoicing system, overriding remote changes.
    def sync_all
    end
  end
end
