module Invoicing
  module SmallInvoice
    module Entity
      class Contact < Base
        def to_hash
          with_id(surname: entry.lastname,
                  name: entry.firstname,
                  email: entry.email,
                  phone: entry.phone,
                  gender: constant(:gender_id),
                  show_department: bool_constant(:show_department))
        end
      end
    end
  end
end
