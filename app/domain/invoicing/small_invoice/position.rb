module Invoicing
  class SmallInvoice
    class Position < Entity

      def to_hash
        # TODO
        {
          type:1,
          number:nil,
          name:'Service Y',
          description:'Cleaning house',
          cost:0,
          unit:7,
          amount:1,
          vat: constant(:vat),
          discount:nil,
          discount_type:0
        }
      end

    end
  end
end
