#  Copyright (c) 2006-2020, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'

class Invoicing::SmallInvoice::InterfaceTest < ActiveSupport::TestCase
  include SmallInvoiceTestHelper

  test '#save_invoice creates' do
    Invoicing::SmallInvoice::InvoiceStore.any_instance.stubs(:save).returns(true)

    assert subject.save_invoice(invoice, [])
  end

  test '#save_invoice updates' do
    invoice.update_column(:invoicing_key, 1)
    Invoicing::SmallInvoice::InvoiceStore.any_instance.stubs(:save).returns(true)

    assert subject.save_invoice(invoice, [1])
  end

  test '#sync_invoice' do
    invoice.update_column(:invoicing_key, 1)
    Invoicing::SmallInvoice::InvoiceSync.any_instance.stubs(:sync).returns(true)

    assert subject.sync_invoice(invoice)
  end

  test '#sync_invoice without invoicing_key' do
    Invoicing::SmallInvoice::InvoiceSync.any_instance.stubs(:sync).returns(true)

    assert_nil subject.sync_invoice(invoice)
  end

  test '#delete_invoice with invoicing_key' do
    invoice.update_column(:invoicing_key, 1)
    stub_auth
    delete_invoice = stub_delete_entity(:invoices, key: 1)
    subject.delete_invoice(invoice)

    assert_requested(delete_invoice)
  end

  test '#delete_invoice without invoicing_key' do
    assert_nil subject.delete_invoice(invoice)
  end

  test '#sync_all' do
    Invoicing::SmallInvoice::ClientSync.expects(:perform).once
    Invoicing::SmallInvoice::InvoiceSync.expects(:sync_unpaid).once

    subject.sync_all
  end

  test '#get_pdf' do
    invoice.update_column(:invoicing_key, 1)
    stub_auth
    get_pdf = stub_request(:get, "#{BASE_URL}/receivables/invoices/1/pdf")

    subject.get_pdf(invoice)

    assert_requested(get_pdf)
  end

  private

  def described_class
    Invoicing::SmallInvoice::Interface
  end

  def subject
    described_class.new
  end

  def invoice
    invoices(:webauftritt_may)
  end
end
