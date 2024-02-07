# frozen_string_literal: true

#  Copyright (c) 2006-2020, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'

module Invoicing
  module SmallInvoice
    class InvoiceSyncTest < ActiveSupport::TestCase
      include SmallInvoiceTestHelper

      test '#sync' do
        get_invoice = stub_get_entity(
          :invoices,
          params: '?with=positions',
          key: 1,
          response: invoice_json
        )

        subject.sync

        assert_requested(get_invoice)
      end

      private

      def described_class
        Invoicing::SmallInvoice::InvoiceSync
      end

      def subject
        described_class.new(invoice)
      end

      def invoice
        invoice = invoices(:webauftritt_may)
        invoice.update_column(:invoicing_key, 1)
        invoice
      end

      def invoice_json
        '{
      "item": {
        "bank_account_id": null,
        "cash_discount_date": null,
        "cash_discount_rate": null,
        "contact_address_id": 512553413,
        "contact_id": 117463039,
        "contact_person_id": 556068567,
        "contact_prepage_address_id": null,
        "created": "2015-11-26 09:18:15",
        "currency": "CHF",
        "date": "2015-11-26",
        "discount_rate": 0.0,
        "discount_type": "P",
        "due": "2015-12-26",
        "id": 699144547,
        "isr_id": 112463152,
        "isr_position": "A",
        "isr_reference_number": "921736000000000000000001546",
        "language": "de",
        "layout_id": 297477064,
        "notes": null,
        "number": "BLSB-DIS-WEI-D2-0023",
        "page_amount": 2,
        "paid_date": null,
        "payment_link_paypal": false,
        "payment_link_paypal_url": null,
        "payment_link_payrexx": false,
        "payment_link_payrexx_url": null,
        "payment_link_postfinance": false,
        "payment_link_postfinance_url": null,
        "payment_link_smartcommerce": false,
        "payment_link_smartcommerce_url": null,
        "period_from": null,
        "period_text": "01.12.2014 - 31.12.2014",
        "period_to": null,
        "positions": [
          {
            "amount": 86.58,
            "catalog_type": "S",
            "description": "",
            "discount_rate": 0.0,
            "discount_type": "P",
            "name": "DIS Weiterentwicklung 2015",
            "number": null,
            "price": 128.4,
            "show_only_total": false,
            "total": 12006.22,
            "type": "N",
            "unit_id": 1,
            "vat": 8.0
          }
        ],
        "signature_id": null,
        "status": "S",
        "total": 12006.2,
        "total_paid": 0.0,
        "vat_included": false
      }
    }'
      end
    end
  end
end
