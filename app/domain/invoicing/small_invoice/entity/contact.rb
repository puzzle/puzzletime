module Invoicing
  module SmallInvoice
    module Entity
      class Contact < Base
        def to_hash
          with_id(surname: entry.lastname,
                  name: entry.firstname,
                  # department: entry.billing_addresses.first.try(:supplement), # undocumented, may not work
                  email: entry.email,
                  phone: entry.phone,
                  gender: constant(:gender_id),
                  # show_department: bool_constant(:show_department)
          )
        end
      end
    end
  end
end
