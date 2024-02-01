#  Copyright (c) 2006-2020, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'
class Invoicing::SmallInvoice::AddressSyncTest < ActiveSupport::TestCase
  include SmallInvoiceTestHelper

  test '#sync without existing client creates address' do
    add_address = stub_add_entity(:addresses, body: address_json, response: address_json_response)

    subject.sync

    assert_requested(add_address)
  end

  test '#sync with existing client but new address creates it' do
    client.update_column(:invoicing_key, 1234)
    edit_address = stub_add_entity(:addresses, client:, body: address_json, response: address_json_response)

    subject.sync

    assert_requested(edit_address)
  end

  test '#sync with existing client and address edits it' do
    client.update_column(:invoicing_key, 1234)
    billing_address.update_column(:invoicing_key, 1)
    edit_address = stub_edit_entity(:addresses, client:, key: 1, body: address_id_json, response: address_json_response)

    subject_with_address.sync

    assert_requested(edit_address)
  end

  private

  def described_class
    Invoicing::SmallInvoice::AddressSync
  end

  def subject
    described_class.new(clients(:puzzle), [])
  end

  def subject_with_address
    described_class.new(clients(:puzzle), [1])
  end

  def client
    clients(:puzzle)
  end

  def billing_address
    billing_addresses(:puzzle)
  end

  def address_json
    '{"street":"Eigerplatz 4","street2":null,"postcode":"3007","city":"Bern","country":"CH"}'
  end

  def address_id_json
    '{"street":"Eigerplatz 4","street2":null,"postcode":"3007","city":"Bern","country":"CH","id":"1"}'
  end

  def address_json_response
    %({"item":#{address_id_json}})
  end
end
