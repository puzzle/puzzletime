# frozen_string_literal: true

require 'test_helper'

class FlatrateTest < ActiveSupport::TestCase
  setup :setup_flatrate
  attr_reader :invoice, :flatrate, :flatrate_monthly, :order, :accounting_post

  test 'not_billed_flatrates_quantity test basic' do
    amount = flatrate.not_billed_flatrates_quantity(Time.zone.parse('2020-06-06'), invoice.id)

    assert_equal amount, flatrate.periodicity[0..5].sum
  end

  test 'not_billed_flatrates_quantity test two years' do
    amount = flatrate.not_billed_flatrates_quantity(Time.zone.parse('2021-12-31'), invoice.id)

    assert_equal amount, flatrate.periodicity.sum * 2
  end

  test 'not_billed_flatrates_quantity test end_date before flatrate active_from' do
    amount = flatrate.not_billed_flatrates_quantity(Time.zone.parse('2019-12-31'), invoice.id)

    assert_equal 0, amount
  end

  test 'not_billed_flatrates_quantity test end_date before after contract end does not add any quantity' do
    amount_overall = flatrate.not_billed_flatrates_quantity(Time.zone.parse('2027-12-31'), invoice.id)
    amount_to_contract_end = flatrate.not_billed_flatrates_quantity(Time.zone.parse('2022-10-01'), invoice.id)

    assert_equal amount_overall, amount_to_contract_end
  end

  test 'not_billed_flatrates_quantity is based on already existing invoice_flatrates for other invoices' do
    amount_old_invoice = flatrate_monthly.not_billed_flatrates_quantity(Time.zone.parse('2020-12-31'), invoice.id)
    build_invoice_flatrate(invoice, flatrate_monthly, 4)
    amount_new_invoice = flatrate_monthly.not_billed_flatrates_quantity(Time.zone.parse('2020-12-31'), Fabricate(:invoice, order: order).id)

    assert_equal amount_old_invoice - 4, amount_new_invoice
  end

  test 'not_billed_flatrates_quantity is not influenced by invoice_flatrates for the same invoices' do
    amount_before = flatrate_monthly.not_billed_flatrates_quantity(Time.zone.parse('2020-12-31'), invoice.id)
    build_invoice_flatrate(invoice, flatrate_monthly, 4)
    amount_after = flatrate_monthly.not_billed_flatrates_quantity(Time.zone.parse('2020-12-31'), invoice.id)

    assert_equal amount_before, amount_after
  end

  private

  def setup_flatrate
    @accounting_post = Fabricate(:accounting_post)
    @order = accounting_post.order
    Fabricate(:contract, order: @order, start_date: '2015-01-01', end_date: '2022-10-10')
    @invoice = Fabricate(:invoice, order: @order)
    @flatrate = Fabricate(:flatrate, active_from: '2020-01-01', accounting_post: accounting_post)
    @flatrate_monthly = Fabricate(:flatrate, active_from: '2020-01-01', accounting_post: accounting_post, periodicity: [0, 0, 3, 0, 0, 3, 0, 0, 3, 0, 0, 3])
  end

  def build_invoice_flatrate(invoice, flatrate, quantity)
    Fabricate(:invoice_flatrate, invoice: invoice, flatrate: flatrate, quantity: quantity)
  end
end
