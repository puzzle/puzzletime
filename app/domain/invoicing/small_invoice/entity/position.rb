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
            cost: post.offered_rate.try(:round, 2),
            unit: constant(:unit_id),
            amount: entry.total_hours.round(2),
            vat: Settings.defaults.vat
          }
        end

        private

        def post
          entry.accounting_post
        end
      end
    end
  end
end
