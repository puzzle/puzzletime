module Invoicing
  module SmallInvoice
    module Entity
      class Position < Base
        def to_hash
          {
            type: constant(:position_type_id),
            number: nil,
            name: entry.name,
            description: nil,
            cost: post.offered_rate,
            unit: constant(:unit_id),
            amount: entry.total_hours,
            vat: constant(:vat),
            discount: discount,
            discount_type: discount_type
          }
        end

        private

        def discount_type
          post.discount_percent? ? 0 : 1
        end

        def discount
          post.discount_percent.presence || post.discount_fixed.presence
        end

        def post
          entry.accounting_post
        end
      end
    end
  end
end
