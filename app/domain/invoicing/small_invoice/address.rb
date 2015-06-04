module Invoicing
  class SmallInvoice
    class Address < Entity

      def to_hash
        with_id({
          street: entry.street,
          code: entry.zip_code,
          city: entry.town,
          country: entry.country
        })
      end

    end
  end
end
