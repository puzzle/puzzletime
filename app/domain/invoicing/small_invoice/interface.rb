#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

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
        Api.instance.get_raw('invoice', :pdf, invoice.invoicing_key)
      end
    end
  end
end
