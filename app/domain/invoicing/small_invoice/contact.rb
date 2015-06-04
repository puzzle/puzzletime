module Invoicing
  class SmallInvoice
    class Contact < Entity

      def to_hash
        with_id({
          surname: contact.lastname,
          name: contact.firstname,
          department: contact.billing_addresses.first.try(:supplement), # undocumented, may not work
          email: contact.email,
          phone: contact.phone,
        })
      end

    end
  end
end
