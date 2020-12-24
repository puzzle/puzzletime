#  Copyright (c) 2006-2020, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'
require 'small_invoice_test_helper'

class Invoicing::SmallInvoice::InvoiceStoreTest < ActiveSupport::TestCase
  setup :stub_auth

  setup do
    billing_address.update_column(:invoicing_key, 2)
    contact.update_column(:invoicing_key, 1)
    client.update_column(:invoicing_key, 1)
  end

  test '#save creates new invoices' do
    add_invoice = stub_add_entity(:invoices, body: invoice_json)

    subject.save([manual_position])

    assert_requested(add_invoice)
  end

  test '#save edits existing invoices' do
    invoice.update_column(:invoicing_key, 1)

    edit_invoice = stub_edit_entity(:invoices, key: 1, body: invoice_json)

    subject.save([manual_position])

    assert_requested(edit_invoice)
  end

  private

  def described_class
    Invoicing::SmallInvoice::InvoiceStore
  end

  def subject
    described_class.new(invoice)
  end

  def invoice
    invoices(:webauftritt_may)
  end

  def billing_address
    invoice.billing_address
  end

  def contact
    billing_address.contact
  end

  def client
    billing_address.client
  end

  def manual_position
    Invoicing::Position.new(AccountingPost.new(offered_rate: 1), 1, 'Manuell')
  end

  def invoice_json
    JSON.parse('{
      "number":"STOPWEBD10001",
      "contact_id":1,
      "contact_address_id":2,
      "contact_person_id":1,
      "date":"2015-06-15",
      "due":"2015-07-14",
      "period":"01.12.2006 - 31.12.2006",
      "currency":"CHF",
      "vat_included":false,
      "language":"de",
      "positions":[
        {
          "type":"N",
          "catalog_type":"S",
          "number":null,
          "name":"Manuell",
          "description":null,
          "price":1.0,
          "vat":7.7,
          "amount":1.0,
          "unit_id":1
        }
      ],
      "texts":[
        {
          "status":"D",
          "title":"Webauftritt gemäss Vertrag web1234",
          "conditions":"Zahlbar innert 45 Tagen ab Rechnungsdatum.",
          "introduction":"Besten Dank für Ihren Auftrag\\n\\nIhre Referenzinformationen:\\norder webauftritt 1234"
        }
      ]
    }').to_json
  end
end
