module Invoicing
  module SmallInvoice
    class Interface
      def create_invoice(invoice, _options = {})
        assert_remote_client_exists(invoice)

        data = Invoicing::SmallInvoice::Entity::Invoice.new(invoice).to_hash
        id = api.add(:invoice, data)
        invoice.update!(invoicing_key: id)
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
        end
      end
    end
  end
end
