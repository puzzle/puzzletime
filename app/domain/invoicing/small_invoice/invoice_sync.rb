#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


module Invoicing
  module SmallInvoice
    # One-way sync of invoices from Small Invoice to PuzzleTime
    class InvoiceSync
      STATUS = {  1 => 'sent',  # sent / open
                  2 => 'paid',  # paid
                  3 => 'sent',  # 1st reminder
                  4 => 'sent',  # 2nd reminder
                  5 => 'sent',  # 3rd reminder
                  6 => 'cancelled', # cancelled
                  7 => 'draft', # draft
                  11 => 'partially_paid', # partially paid
                  12 => 'sent', # reminder
                  99 => 'deleted' }.freeze # deleted

      attr_reader :invoice
      class_attribute :rate_limiter
      self.rate_limiter = RateLimiter.new(Settings.small_invoice.request_rate)

      class << self
        def sync_unpaid
          unpaid_invoices.find_each do |invoice|
            begin
              new(invoice).sync
            rescue => error
              notify_sync_error(error, invoice)
            end
          end
        end

        private

        def unpaid_invoices
          Invoice
            .joins(order: :status)
            .where.not(status: 'paid', invoicing_key: nil, order_statuses: { closed: true })
        end

        def notify_sync_error(error, invoice)
          parameters = record_to_params(invoice)
          parameters[:code] = error.code if error.respond_to?(:code)
          parameters[:data] = error.data if error.respond_to?(:data)
          Airbrake.notify(error, parameters)
          Raven.capture_exception(error, extra: parameters)
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
          delete_invoice(true)
        elsif e.code == 99_410 # object does not exist
          delete_invoice
        else
          raise
        end
      end

      private

      def sync_remote(item)
        if STATUS[item['status']] == 'deleted'
          delete_invoice
        else
          update_values(item)
        end
      end

      def update_values(item)
        invoice.update_columns(status: STATUS[item['status']],
                               due_date: item['due'],
                               billing_date: item['date'],
                               total_amount: total_amount_without_vat(item),
                               total_hours: total_hours(item))
      end

      def delete_invoice(force = false)
        if invoice.destroyable? || force
          invoice.destroy!
        elsif invoice.status != 'deleted'
          invoice.update_attribute(:status, 'deleted')
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

      # item['totalamount'] always includes vat
      # item['vat_included'] tells whether position totals already include vat or not.
      def total_amount_without_vat(item)
        vat_included = !item['vat_included'].zero?
        item['positions'].select { |p| p['cost'] }.map do |p|
          total = p['cost'] * p['amount']
          total -= position_discount(p, total)
          total -= position_included_vat(p, total) if vat_included
          total
        end.sum
      end

      def position_discount(p, total)
        return 0 unless p['discount']

        if p['discount_type'].zero? # percent
          total * p['discount'] / 100.0
        else # amount
          p['discount']
        end
      end

      def position_included_vat(p, total)
        return 0 unless p['vat']

        total * p['vat'] / (100.0 + p['vat'])
      end

      def api
        Api.instance
      end
    end
  end
end
