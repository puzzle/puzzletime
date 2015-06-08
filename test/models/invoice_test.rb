# encoding: utf-8
# == Schema Information
#
# Table name: invoices
#
#  id                 :integer          not null, primary key
#  order_id           :integer          not null
#  billing_date       :date             not null
#  due_date           :date             not null
#  total_amount       :decimal(12, 2)   not null
#  total_hours        :float            not null
#  reference          :string           not null
#  period_from        :date             not null
#  period_to          :date             not null
#  status             :string           not null
#  add_vat            :boolean          default(TRUE), not null
#  billing_address_id :integer          not null
#  invoicing_key      :string
#  grouping           :integer          default(0)
#

require 'test_helper'

class InvoiceTest < ActiveSupport::TestCase

  setup do
    Invoicing.instance = nil
    invoice.employees = [employees(:pascal), employees(:mark), employees(:lucien)]
    invoice.work_items << work_items(:webauftritt)
  end

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

  test 'generates invoice number' do
    i = invoice.dup
    i.reference = nil
    i.save!
    assert_equal 'STOPWEBD10002', i.reference
  end

  test 'updates totals when validating' do
    invoice.total_amount = invoice.total_hours = 0
    invoice.valid?
    assert_equal 18, invoice.total_hours
    assert_equal 2520, invoice.total_amount
  end

  test 'manual_invoice? is true only when grouping == "manual"' do
    invoice.grouping = 'manual'
    assert invoice.manual_invoice?

    (Invoice.groupings.keys - ['manual']).each do |grouping|
      invoice.grouping = grouping
      refute invoice.manual_invoice?
    end
  end

  test 'grouping= accepts only valid values' do
    %w(accounting_posts employees manual).each do |grouping|
      invoice.grouping = grouping
      assert_equal grouping, invoice.grouping
    end

    assert_raises ArgumentError do
      invoice.grouping = 'asdf'
    end
  end

  test 'calculate_total_amount' do
    skip 'not implemented'
  end

  test 'positions' do
    skip 'not implemented'
  end

  test 'worktimes' do
    skip 'not implemented'
  end

  test 'save_remote_invoice' do
    skip 'not implemented'
  end



  test 'all employees' do
    skip 'anpassen'
    assert_equal employees(:mark, :lucien, :pascal), builder.all_employees
  end

  test 'all accounting posts' do
    skip 'anpassen'
    assert_equal [accounting_posts(:webauftritt)], builder.all_accounting_posts
  end

  test 'build all positions' do
    skip 'anpassen'
    invoice.period_from = Date.new(2006, 1, 1)
    positions = builder.build_positions
    assert_equal 1, positions.size
    assert_equal 'Webauftritt', positions.first.name
    assert_equal 18, positions.first.total_hours
    assert_equal 18 * 140, positions.first.total_amount
  end

  test 'build all employees' do
    skip 'anpassen'
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
    skip 'anpassen'
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
    skip 'anpassen'
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
    skip 'anpassen'
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
    skip 'anpassen'
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
    skip 'anpassen'
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

end

class InvoiceTransactionTest < ActiveSupport::TestCase

  self.use_transactional_fixtures = false

  test 'generates different parallel invoice numbers' do
    skip 'failing'
    ActiveRecord::Base.clear_active_connections!
    10.times.collect do
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          invoices(:webauftritt_may).dup.save!
        end
      end
    end.each(&:join)

    assert_equal 11, clients(:swisstopo).last_invoice_number
    assert_equal 11, Invoice.pluck(:reference).uniq.size
  end

end
