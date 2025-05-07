# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# {{{
# == Schema Information
#
# Table name: invoices
#
#  id                 :integer          not null, primary key
#  billing_date       :date             not null
#  due_date           :date             not null
#  grouping           :integer          default("accounting_posts"), not null
#  invoicing_key      :string
#  period_from        :date             not null
#  period_to          :date             not null
#  reference          :string           not null
#  status             :string           not null
#  total_amount       :decimal(12, 2)   not null
#  total_hours        :float            not null
#  created_at         :datetime
#  updated_at         :datetime
#  billing_address_id :integer          not null
#  order_id           :integer          not null
#
# Indexes
#
#  index_invoices_on_billing_address_id  (billing_address_id)
#  index_invoices_on_order_id            (order_id)
#
# }}}

require 'test_helper'

class InvoiceTest < ActiveSupport::TestCase
  setup do
    @worktime_lw2 = worktimes(:wt_lw_webauftritt).dup.tap do |w|
      w.work_date += 1.day
      w.hours = 10
      w.save!
    end
    Invoicing.instance = nil
    invoice.employees = [employees(:pascal), employees(:mark), employees(:lucien)]
    invoice.work_items << work_items(:webauftritt)
  end

  teardown do
    Invoicing.instance = nil
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

  test 'billing address may belong to any client' do
    invoice.billing_address = billing_addresses(:puzzle)

    assert_valid invoice
  end

  test 'validates period_from and period to' do
    invoice.period_from = invoice.period_to = nil

    assert_not_predicate invoice, :valid?
    assert_includes invoice.errors.messages[:period_from], 'muss ausgefüllt werden'
    assert_includes invoice.errors.messages[:period_to], 'muss ausgefüllt werden'

    invoice.period_from = invoice.period_to = '01.20.2000'

    assert_not_predicate invoice, :valid?
    assert_includes invoice.errors.messages[:period_from], 'muss ausgefüllt werden'
    assert_includes invoice.errors.messages[:period_to], 'muss ausgefüllt werden'

    invoice.period_from = '02.12.2000'
    invoice.period_to = '01.12.2000'

    assert_not_predicate invoice, :valid?
    assert_includes invoice.errors.messages[:period_to], 'muss nach von sein.'

    invoice.period_to = invoice.period_from

    assert_predicate invoice, :valid?
  end

  test 'validates order ist not closed' do
    orders(:webauftritt).update!(status: order_statuses(:abgeschlossen))

    assert_not_predicate invoice, :valid?
  end

  test 'invoices with closed order cannot be destroyed' do
    orders(:webauftritt).update!(status: order_statuses(:abgeschlossen))

    assert_not invoice.destroy
  end

  test 'generates invoice number' do
    second_invoice = invoice.dup.tap do |i|
      i.reference = nil
      i.save!
    end

    assert_equal %w[STOP WEB D1 0002].join, second_invoice.reference
  end

  test 'includes category shortname in invoice number' do
    second_invoice = invoice_with_category.dup.tap do |i|
      i.reference = nil
      i.save!
    end

    assert_equal %w[PITC HIT DEM D2 0002].join, second_invoice.reference
  end

  test 'updates totals when validating' do
    invoice.total_amount = invoice.total_hours = 0
    invoice.valid?

    assert_equal 28, invoice.total_hours.to_f
    assert_equal 3920, invoice.total_amount.to_f
  end

  test 'rounds total_amount to nearest 5 cents' do
    accounting_posts(:webauftritt).update_attribute(:offered_rate, 1.01)
    invoice.valid?

    assert_in_delta(28.28, invoice.send(:positions).sum(&:total_amount).to_f)
    assert_in_delta(28.30, invoice.total_amount.to_f)
  end

  test 'manual_invoice? is true only when grouping == "manual"' do
    invoice.grouping = 'manual'

    assert_predicate invoice, :manual_invoice?

    (Invoice.groupings.keys - ['manual']).each do |grouping|
      invoice.grouping = grouping

      assert_not_predicate invoice, :manual_invoice?
    end
  end

  test 'grouping= accepts only valid values' do
    %w[accounting_posts employees manual].each do |grouping|
      invoice.grouping = grouping

      assert_equal grouping, invoice.grouping
    end

    assert_raises ArgumentError do
      invoice.grouping = 'asdf'
    end
  end

  test 'calculated_total_amount when grouping = manual' do
    invoice.manual!

    assert_in_delta(1.0, invoice.calculated_total_amount.to_f)
  end

  %w[employees accounting_posts].each do |grouping|
    test "calculated_total_amount when grouping = #{grouping}" do
      invoice.grouping = grouping

      assert_equal 3920, invoice.calculated_total_amount.to_f
    end
  end

  test 'worktimes' do
    worktimes = invoice.send(:worktimes)

    assert_equal 3, worktimes.size
    assert_equal [worktimes(:wt_mw_webauftritt), worktimes(:wt_lw_webauftritt), @worktime_lw2].sort, worktimes.sort
  end

  test 'worktimes does not include worktimes belonging to other invoice' do
    @worktime_lw2.update_attribute(:invoice_id, invoice.id + 1)
    worktimes = invoice.send(:worktimes)

    assert_equal 2, worktimes.size
    assert_equal [worktimes(:wt_mw_webauftritt), worktimes(:wt_lw_webauftritt)].sort, worktimes.sort
  end

  test 'worktimes included only for selected invoice employees' do
    invoice.employees = [employees(:mark)]
    worktimes = invoice.send(:worktimes)

    assert_equal 1, worktimes.size
    assert_equal [worktimes(:wt_mw_webauftritt)], worktimes
  end

  test 'worktimes included only for selected invoice work_items' do
    other_work_item = Fabricate(:work_item, parent_id: work_items(:webauftritt).parent_id)
    worktimes(:wt_lw_webauftritt).update_column(:work_item_id, other_work_item.id)
    worktimes = invoice.send(:worktimes)

    assert_equal 2, worktimes.size
    assert_equal [worktimes(:wt_mw_webauftritt), @worktime_lw2].sort, worktimes.sort
  end

  test 'build_positions when grouping is manual' do
    invoice.manual!
    positions = invoice.send(:build_positions)

    assert 1, positions.size
    assert_equal 'Manuell', positions.first.name
    assert_equal 1, positions.first.total_hours
    assert_equal 1, positions.first.total_amount
  end

  test 'build_positions when grouping is employees' do
    invoice.employees!
    positions = invoice.send(:build_positions).sort_by(&:name)

    assert_equal 2, positions.size
    expected_position_names = [employees(:mark), employees(:lucien)].map { |e| "Webauftritt - #{e}" }

    assert_equal expected_position_names, positions.map(&:name)

    assert_equal 7, positions.first.total_hours
    assert_equal 980, positions.first.total_amount.to_f

    assert_equal 21, positions.second.total_hours
    assert_equal 2940, positions.second.total_amount.to_f
  end

  test 'build_positions when grouping is work_items' do
    invoice.accounting_posts!
    positions = invoice.send(:build_positions)

    assert_equal 1, positions.size
    assert_equal accounting_posts(:webauftritt).name, positions.first.name

    assert_equal 28, positions.first.total_hours
    assert_equal 3920, positions.first.total_amount.to_f
  end

  test 'save assigns invoicing key when successful' do
    Invoicing.instance = mock
    Invoicing.instance.stubs(:save_invoice).returns('abc123')
    invoice.save!

    assert_equal 'abc123', invoice.invoicing_key
  end

  test 'save does not succeed when Invoicing::Error, adds validation error' do
    Invoicing.instance = mock
    Invoicing.instance.stubs(:save_invoice).raises(Invoicing::Error.new('some invoicing error'))
    invoice.save

    assert_predicate invoice, :changed?
    assert_nil invoice.invoicing_key
    assert_equal({ base: ['Fehler im Invoicing Service: some invoicing error'] }, invoice.errors.messages)
  end

  test 'save assigns worktimes to invoice when successful' do
    Invoicing.instance = mock
    Invoicing.instance.stubs(:save_invoice).returns('abc123')
    # committed worktimes may still be assigned to an invoice
    employees(:lucien).update!(committed_worktimes_at: '31.1.2015')
    invoice.save!

    assert_equal invoice, worktimes(:wt_mw_webauftritt).reload.invoice
    assert_equal invoice, worktimes(:wt_lw_webauftritt).reload.invoice
    assert_equal invoice, @worktime_lw2.reload.invoice
  end

  test 'save assigns worktimes of closed accounting posts to invoice when successful' do
    Invoicing.instance = mock
    Invoicing.instance.stubs(:save_invoice).returns('abc123')
    accounting_posts(:webauftritt).update!(closed: true)
    invoice.save!

    assert_equal invoice, worktimes(:wt_mw_webauftritt).reload.invoice
    assert_equal invoice, worktimes(:wt_lw_webauftritt).reload.invoice
    assert_equal invoice, @worktime_lw2.reload.invoice
  end

  test 'save does not assign worktimes when Invoicing::Error' do
    Invoicing.instance = mock
    Invoicing.instance.stubs(:save_invoice).raises(Invoicing::Error.new('some invoicing error'))
    invoice.save

    assert_not_equal invoice, worktimes(:wt_mw_webauftritt).reload.invoice
    assert_not_equal invoice, worktimes(:wt_lw_webauftritt).reload.invoice
    assert_not_equal invoice, @worktime_lw2.reload.invoice
  end

  test 'save clears worktimes when setting grouping to manual' do
    invoice.save

    assert_not_empty Worktime.where(invoice_id: invoice.id)
    invoice.grouping = 'manual'
    invoice.save

    assert_empty Worktime.where(invoice_id: invoice.id)
  end

  test 'save removes worktimes of employees not assigned to invoice' do
    invoice.save
    # assert precondition
    assert_not_empty Worktime.where(employee: employees(:mark), invoice:)

    # remove employee, assert worktimes unassigned
    invoice.employees -= [employees(:mark)]
    invoice.save

    assert_empty Worktime.where(employee: employees(:mark), invoice:)
  end

  test 'create stores last billing address on order' do
    assert_nil orders(:webauftritt).billing_address_id
    invoice = Invoice.new(invoices(:webauftritt_may).attributes)
    invoice.id = nil
    invoice.billing_address = billing_addresses(:swisstopo_2)
    invoice.save!

    assert_equal billing_addresses(:swisstopo_2).id, orders(:webauftritt).reload.billing_address_id
  end

  test 'update stores last billing address on order' do
    assert_nil orders(:webauftritt).billing_address_id
    invoice = invoices(:webauftritt_may)
    invoice.billing_address = billing_addresses(:swisstopo_2)
    invoice.save!

    assert_equal billing_addresses(:swisstopo_2).id, orders(:webauftritt).reload.billing_address_id
  end

  test 'delete deletes remote as well' do
    Invoicing.instance = mock
    Invoicing.instance.expects(:delete_invoice)
    assert_difference('Invoice.count', -1) { assert invoice.destroy }
  end

  test 'delete adds error message if invoicing error' do
    Invoicing.instance = mock
    Invoicing.instance.expects(:delete_invoice).raises(Invoicing::Error.new('some invoicing error'))
    assert_no_difference('Invoice.count') { assert_not invoice.destroy }
    assert_equal ['Fehler im Invoicing Service: some invoicing error'], invoice.errors[:base]
  end

  private

  def invoice
    invoices(:webauftritt_may)
  end

  def invoice_with_category
    @invoice_with_category ||= begin
      order = orders(:hitobito_demo)
      Fabricate(:contract, order:) unless order.contract
      Fabricate(:invoice,
                order:,
                work_items: [work_items(:hitobito_demo_app)],
                employees: [employees(:pascal)],
                period_to: Time.zone.today.at_end_of_month)
    end
  end
end

class InvoiceTransactionTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  test 'generates different parallel invoice numbers' do
    ActiveRecord::Base.connection_handler.clear_active_connections!
    Array.new(10) do
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          invoices(:webauftritt_may).dup.save!
        end
      end
    end.each(&:join)

    assert_equal 11, clients(:swisstopo).last_invoice_number
    assert_equal 11, Invoice.distinct.pluck(:reference).size
  end
end
