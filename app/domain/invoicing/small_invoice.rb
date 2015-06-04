module Invoicing
  class SmallInvoice

    def create_invoice(invoice, options = {})
      # TODO add client, billing address and contact if not in invoicing yet
      data = Invoice.new(invoice).to_hash
      id = api.add(:invoice, data)
      invoice.update!(invoicing_key: id)
    end

    def sync_all
      sync_clients
    end

    private

    def sync_clients
      ::Client.includes(:work_item, :contacts, :billing_addresses).find_each do |client|
        next if client.billing_addresses.empty? # required by small invoice
        
        data = Client.new(client).to_hash
        if client.invoicing_key?
          id = api.add(:client, data)
          client.update!(invoicing_key: id)
        else
          api.edit(:client, data)
        end
      end
    end

    def api
      @api ||= Invoicing::SmallInvoice::Api.new
    end

  end
end
