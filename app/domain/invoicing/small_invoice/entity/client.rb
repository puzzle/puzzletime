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
            contacts: entry.contacts.collect.with_index do |c, i|
              # Set primary on the first contact to ensure we always have a
              # primary contact for this client.
              # Clients can only have one primary contact,
              # setting more than one contact to primary will overwrite the
              # existing one.
              # See #20498
              Entity::Contact.new(c).to_hash.update(primary: i == 0)
            end
          }
        end
      end
    end
  end
end
