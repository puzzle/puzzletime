#  Copyright (c) 2006-2020, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'
require 'small_invoice_test_helper'

class Invoicing::SmallInvoice::ApiTest < ActiveSupport::TestCase
  setup :stub_auth

  test '#list' do
    id   = id(:contacts)
    path = path(:contacts)
    get_contacts = stub_get_entity(:contacts)

    list = subject.list(path)

    assert_requested(get_contacts)
    assert_instance_of Array, list

    contact = list.first
    assert_equal id, contact['id']
  end

  test '#get' do
    id = id(:contacts)
    path = path(:contacts, key: id)
    get_contact = stub_get_entity(:contacts, key: id)

    contact = subject.get(path)
    assert_requested(get_contact)
    assert_equal id, contact['id']
  end

  test '#add' do
    id = id(:contacts)
    path = path(:contacts)
    add_contact = stub_add_entity(:contacts)

    contact = subject.add(path, new_contact)

    assert_requested(add_contact)
    assert_equal id, contact['id']
  end

  test '#edit' do
    path = path(:contacts)
    edit_contact = stub_edit_entity(:contacts)

    assert_nil subject.edit(path, new_contact)
    assert_requested(edit_contact)
  end

  test '#delete' do
    path = path(:contacts)
    delete_contact = stub_delete_entity(:contacts)

    assert_nil subject.delete(path)
    assert_requested(delete_contact)
  end

  private

  def subject
    Invoicing::SmallInvoice::Api.instance
  end
end
