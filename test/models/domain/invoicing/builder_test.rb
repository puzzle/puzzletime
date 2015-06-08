require 'test_helper'

class Invoicing::BuilderTest < ActiveSupport::TestCase


  test 'all employees' do
    assert_equal employees(:mark, :lucien, :pascal), builder.all_employees
  end

  test 'all accounting posts' do
    assert_equal [accounting_posts(:webauftritt)], builder.all_accounting_posts
  end

  test 'build all positions' do
    invoice.period_from = Date.new(2006, 1, 1)
    positions = builder.build_positions
    assert_equal 1, positions.size
    assert_equal 'Webauftritt', positions.first.name
    assert_equal 18, positions.first.total_hours
    assert_equal 18 * 140, positions.first.total_amount
  end

  test 'build all employees' do
    builder.grouping = :employees
    invoice.period_from = Date.new(2006, 1, 1)
    positions = builder.build_positions
    assert_equal 2, positions.size
    assert_equal 'Webauftritt - Waber Mark', positions.first.name
    assert_equal 7, positions.first.total_hours
    assert_equal 7 * 140, positions.first.total_amount
    assert_equal 'Webauftritt - Weller Lucien', positions.last.name
    assert_equal 11, positions.last.total_hours
  end

  test 'build selected employees' do
    builder.grouping = :employees
    builder.employees = employees(:mark)
    invoice.period_from = Date.new(2006, 1, 1)
    positions = builder.build_positions
    assert_equal 1, positions.size
    assert_equal 'Webauftritt - Waber Mark', positions.first.name
    assert_equal 7, positions.first.total_hours
    assert_equal 7 * 140, positions.first.total_amount
  end

  test 'save' do
    Invoicing.instance = stub(:save_invoice)
    invoice.period_from = Date.new(2006, 1, 1)

    assert_equal true, builder.save

    invoice.reload
    assert_equal 18, invoice.total_hours
    assert_equal 18 * 140, invoice.total_amount
    assert_equal invoice.id, worktimes(:wt_mw_webauftritt).invoice_id
    assert_equal invoice.id, worktimes(:wt_lw_webauftritt).invoice_id
    assert_equal nil, worktimes(:wt_pz_webauftritt).invoice_id
  end

  test 'save with validation error' do
    Invoicing.instance = mock
    Invoicing.instance.expects(:save_invoice).never
    invoice.period_from = Date.new(2015, 12, 1)

    assert_equal false, builder.save
    assert_match /nach von/, invoice.errors.full_messages.join

    assert_equal nil, worktimes(:wt_mw_webauftritt).invoice_id
    assert_equal nil, worktimes(:wt_lw_webauftritt).invoice_id
    assert_equal nil, worktimes(:wt_pz_webauftritt).invoice_id
  end

  test 'save with exception' do
    invoice.update!(total_hours: 0, total_amount: 0)
    Invoicing.instance = mock
    Invoicing.instance.expects(:save_invoice).raises(Invoicing::Error.new('No good'))
    invoice.period_from = Date.new(2006, 1, 1)

    assert_equal false, builder.save
    assert_equal 'No good', invoice.errors.full_messages.join

    invoice.reload
    assert_equal 0, invoice.total_hours
    assert_equal 0, invoice.total_amount
    assert_equal nil, worktimes(:wt_mw_webauftritt).invoice_id
    assert_equal nil, worktimes(:wt_lw_webauftritt).invoice_id
    assert_equal nil, worktimes(:wt_pz_webauftritt).invoice_id
  end

  test 'save manual' do
    Invoicing.instance = stub(:save_invoice)
    invoice.period_from = Date.new(2006, 1, 1)
    builder.grouping = :manual

    assert_equal true, builder.save

    invoice.reload
    assert_equal 0, invoice.total_hours
    assert_equal 0, invoice.total_amount
    assert_equal nil, worktimes(:wt_mw_webauftritt).invoice_id
    assert_equal nil, worktimes(:wt_lw_webauftritt).invoice_id
    assert_equal nil, worktimes(:wt_pz_webauftritt).invoice_id
  end


  private

  def invoice
    invoices(:webauftritt_may)
  end

  def builder
    @builder ||= Invoicing::Builder.new(invoice)
  end

end
