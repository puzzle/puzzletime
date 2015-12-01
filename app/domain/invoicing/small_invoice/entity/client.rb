module Invoicing
  module SmallInvoice
    module Entity
      class Client < Base
        def to_hash
          {
            number: entry.shortname,
            name: entry.name,
            type: constant(:client_type),
            language: constant(:language),
            einvoice_account_id: entry.e_bill_account_key,
            addresses: entry.billing_addresses.collect { |a| Address.new(a).to_hash },
            contacts: entry.contacts.collect { |c| Entity::Contact.new(c).to_hash }
          }
        end
      end
    end
  end
end
