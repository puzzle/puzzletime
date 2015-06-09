module Invoicing
  module SmallInvoice
    class Interface < Invoicing::Interface

      def save_invoice(invoice, positions)
        InvoiceStore.new(invoice).save(positions)
      end

      def sync_invoice(invoice)
        return unless invoice.invoicing_key?

        InvoiceSync.new(invoice).sync
      end

      def sync_all
        ClientSync.perform
        InvoiceSync.sync_unpaid
      end

      def api
        @api ||= Api.new
      end

    end
  end
end
