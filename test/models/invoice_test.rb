require 'test_helper'

class InvoiceTest < ActiveSupport::TestCase

  test 'title with contract' do
    assert_equal 'Webauftritt gemäss Vertrag web1234', invoice.title
  end

  test 'period must be positive' do
    invoice.period_to = invoice.period_from
    assert_valid invoice
    invoice.period_to = invoice.period_to - 1.day
    assert_not_valid invoice, :period_to
  end

  test 'billing address must belong to order client' do
    invoice.billing_address = billing_addresses(:puzzle)
    assert_not_valid invoice, :billing_address_id
  end


  private

  def invoice
    invoices(:webauftritt_may)
  end

end
