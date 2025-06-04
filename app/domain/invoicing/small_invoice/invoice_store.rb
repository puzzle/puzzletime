# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module Invoicing
  module SmallInvoice
    # Saves invoices to Small Invoice
    class InvoiceStore
      attr_reader :invoice

      def initialize(invoice)
        @invoice = invoice
      end

      # Save an invoice with the given positions to remote and returns the invoicing_key
      def save(positions, invoice_flatrates)
        assert_remote_client_exists

        data = Invoicing::SmallInvoice::Entity::Invoice.new(invoice, positions, invoice_flatrates).to_hash
        if invoice.invoicing_key?
          api.edit(:invoice, invoice.invoicing_key, data)
          invoice.invoicing_key
        else
          api.add(:invoice, data)
        end
      end

      private

      def assert_remote_client_exists
        address = invoice.billing_address
        client = address.client
        if client.invoicing_key.blank? ||
           address.invoicing_key.blank? ||
           (address.contact && address.contact.invoicing_key.blank?)
          ClientSync.new(client).sync
          address.reload # required to get the newly set invoicing_key in this instance
        end
      end

      def api
        Api.instance
      end
    end
  end
end
