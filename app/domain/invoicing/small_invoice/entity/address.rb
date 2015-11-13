module Invoicing
  module SmallInvoice
    module Entity
      class Address < Base
        def to_hash
          street, street2 = entry.supplement? ? [entry.supplement, entry.street] : [entry.street, nil]
          with_id(street: street,
                  street2: street2,
                  code: entry.zip_code,
                  city: entry.town,
                  country: entry.country)
        end
      end
    end
  end
end
