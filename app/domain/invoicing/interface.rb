module Invoicing
  class Interface
    # Stores a new or an existing invoice with the given positions in the remote system.
    def save_invoice(invoice, positions)
    end

    # Fetches and updates the data for the given invoice from the remote system.
    # The invoice will be destroyed if the remote system deleted it.
    def sync_invoice(invoice)
    end

    # Sync all entities to the invoicing system, overriding remote changes.
    def sync_all
    end
  end
end
