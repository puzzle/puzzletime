module Invoicing
  module SmallInvoice
    module Entity
      class Base
        attr_reader :entry

        def initialize(entry)
          @entry = entry
        end

        private

        def constant(key)
          Settings.small_invoice.constants.send(key)
        end

        def bool_constant(key)
          constant(key) ? 1 : 0
        end

        def with_id(hash)
          hash.tap { hash[:id] = entry.invoicing_key if entry.invoicing_key? }
        end
      end
    end
  end
end
