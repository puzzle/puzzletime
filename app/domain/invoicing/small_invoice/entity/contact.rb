module Invoicing
  module SmallInvoice
    module Entity
      class Contact < Base
        def to_hash
          with_id(surname: contact.lastname,
                  name: contact.firstname,
                  department: contact.billing_addresses.first.try(:supplement), # undocumented, may not work
                  email: contact.email,
                  phone: contact.phone)
        end
      end
    end
  end
end
