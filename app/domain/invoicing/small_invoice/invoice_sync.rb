module Invoicing
  module SmallInvoice
    # One-way sync of invoices from Small Invoice to PuzzleTime
    class InvoiceSync

      STATUS = {  1 => 'sent',  # sent / open
                  2 => 'paid',  # paid
                  3 => 'sent',  # 1st reminder
                  4 => 'sent',  # 2nd reminder
                  5 => 'sent',  # 3rd reminder
                  6 => 'draft', # cancelled
                  7 => 'draft', # draft
                 99 => 'deleted', # deleted
                 }

      attr_reader :invoice

      class << self

        def sync_unpaid
          Invoice.where.not(status: 'paid', invoicing_key: nil).find_each do |invoice|
            new(invoice).sync
          end
        end

      end

      def initialize(invoice)
        @invoice = invoice
      end

      # Fetch an invoice from remote and update the local values
      def sync
        item = api.get(:invoice, invoice.invoicing_key)
        sync_remote(item)
      rescue Invoicing::Error => e
        if e.code == 15016 # no rights / not found
          destroy_unpaid
        else
          raise
        end
      end

      private

      def sync_remote(item)
        if STATUS[item['status']] == 'deleted'
          destroy_unpaid
        else
          update_values(item)
        end
      end

      def update_values(item)
        invoice.status = STATUS[item['status']]
        invoice.due_date = item['due']
        invoice.billing_date = item['date']
        invoice.add_vat = item['vat_included'] == 0
        invoice.total_amount = total_amount(item)
        invoice.total_hours = total_hours(item)
        invoice.save!
      end

      def destroy
        invoice.destroy! unless invoice.status == 'paid'
      end

      def total_amount(item)
        if item['vat_included'] == 0
          item['totalamount'] / (1 + Settings.small_invoice.constants.vat / 100.0)
        else
          item['totalamount']
        end
      end

      def total_hours(item)
        item['positions'].select do |p|
          p['type'] == Settings.small_invoice.constants.position_type_id &&
          p['unit'] == Settings.small_invoice.constants.unit_id
        end.collect do |p|
          p['amount']
        end.sum
      end

      def api
        Invoicing.instance.api
      end

    end
  end
end
