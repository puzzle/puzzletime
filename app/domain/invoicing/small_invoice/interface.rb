module Invoicing
  module SmallInvoice
    class Interface
      def save_invoice(invoice, positions)
        assert_remote_client_exists(invoice)

        data = Invoicing::SmallInvoice::Entity::Invoice.new(invoice, positions).to_hash
        if invoice.invoicing_key?
          api.edit(:invoice, invoice.invoicing_key, data)
        else
          id = api.add(:invoice, data)
          invoice.update_column(:invoicing_key, id)
        end
      end

      def sync_all
        ClientSync.perform
      end

      def api
        @api ||= Api.new
      end

      private

      def assert_remote_client_exists(invoice)
        client = invoice.order.client
        address = invoice.billing_address
        if client.invoicing_key.blank? ||
           address.invoicing_key.blank? ||
           (address.contact && address.contact.invoicing_key.blank?)
          ClientSync.new(client).sync
          address.reload # required to get the newly set invoicing_key in this instance
        end
      end
    end
  end
end
