module Invoicing
  module SmallInvoice
    module Entity
      class Client < Base
        def to_hash
          {
            number: entry.id,
            name: entry.name,
            type: constant(:client_type),
            language: constant(:language),
            addresses: entry.billing_addresses.collect { |a| Address.new(a).to_hash },
            contacts: entry.contacts.collect { |c| Contact.new(c).to_hash }
          }
        end
      end
    end
  end
end
