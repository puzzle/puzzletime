module Invoicing
  module SmallInvoice
    module Entity
      class Address < Base
        def to_hash
          with_id(street: entry.street,
                  code: entry.zip_code,
                  city: entry.town,
                  country: entry.country)
        end
      end
    end
  end
end
