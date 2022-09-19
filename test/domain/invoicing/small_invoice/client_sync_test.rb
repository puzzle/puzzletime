#  Copyright (c) 2006-2020, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'

class Invoicing::SmallInvoice::ClientSyncTest < ActiveSupport::TestCase
  include SmallInvoiceTestHelper

  test '#sync' do
    # updates contacts
    get_contacts = stub_get_entity(:contacts)
    add_contact  = stub_add_entity(:contacts)

    stub_syncs

    subject.sync

    assert_requested(get_contacts)
    assert_requested(add_contact)
  end

  private

  def described_class
    Invoicing::SmallInvoice::ClientSync
  end

  def subject
    described_class.new(clients(:puzzle))
  end

  def stub_syncs
    contact_sync = mock
    contact_sync.expects(:sync).once
    Invoicing::SmallInvoice::ContactSync
      .stubs(:new)
      .returns(contact_sync)

    address_sync = mock
    address_sync.expects(:sync).once
    Invoicing::SmallInvoice::AddressSync
      .stubs(:new)
      .returns(address_sync)
  end
end
