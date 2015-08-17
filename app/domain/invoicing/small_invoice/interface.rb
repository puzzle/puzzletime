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

      def delete_invoice(invoice)
        return unless invoice.invoicing_key?

        Api.instance.delete(:invoice, invoice.invoicing_key)
      end

      def sync_all
        ClientSync.perform
        InvoiceSync.sync_unpaid
      end

      def get_pdf(invoice)
        Api.instance.raw('invoice', invoice.invoicing_key, :pdf)
      end
    end
  end
end
