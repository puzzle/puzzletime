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
                  11 => 'partially_paid', # partially paid
                  12 => 'sent', # reminder
                  99 => 'deleted' }.freeze # deleted.tap { |h| h.default = 'unknown' } # unknown status value (i.e. newly introduced status)

      attr_reader :invoice
      class_attribute :rate_limiter
      self.rate_limiter = RateLimiter.new(Settings.small_invoice.request_rate)

      class << self
        def sync_unpaid
          Invoice.where.not(status: 'paid', invoicing_key: nil).find_each do |invoice|
            begin
              new(invoice).sync
            rescue => error
              notify_sync_error(error, invoice)
            end
          end
        end

        private

        def notify_sync_error(error, invoice)
          parameters = record_to_params(invoice)
          Airbrake.notify(error, cgi_data: ENV.to_hash, parameters: parameters)
        end

        def record_to_params(record, prefix = 'invoice')
          {
            "#{prefix}_id"            => record.id,
            "#{prefix}_invoicing_key" => record.invoicing_key,
            "#{prefix}_label"         => record.try(:label) || record.to_s,
            "#{prefix}_errors"        => record.errors.messages,
            "#{prefix}_changes"       => record.changes
          }
        end
      end

      def initialize(invoice)
        @invoice = invoice
      end

      # Fetch an invoice from remote and update the local values
      def sync
        item = rate_limiter.run { api.get(:invoice, invoice.invoicing_key) }
        sync_remote(item)
      rescue Invoicing::Error => e
        if e.code == 15_016 # no rights / not found
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
        invoice.update_columns(status: STATUS[item['status']],
                               due_date: item['due'],
                               billing_date: item['date'],
                               add_vat: item['vat_included'] == 0,
                               total_amount: total_amount(item),
                               total_hours: total_hours(item))
      end

      def destroy_unpaid
        invoice.destroy! unless invoice.status == 'paid'
      end

      def total_amount(item)
        if item['vat_included'] == 0
          item['totalamount'] / (1 + Settings.defaults.vat / 100.0)
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
        Api.instance
      end
    end
  end
end
