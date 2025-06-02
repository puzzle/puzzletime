# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'

class Invoice
  class ReportTest < ActiveSupport::TestCase
    ### filtering

    setup :create_invoices

    test 'contains all invoices without filters' do
      assert_equal 3, report.entries.size
    end

    test 'filter by status' do
      report(status: :draft)

      assert_equal [@invc2.reference, invoices(:webauftritt_may).reference].sort, report.entries.collect(&:reference).sort
    end

    test 'filter by responsible' do
      report(responsible_id: employees(:long_time_john).id)

      assert_equal [invoices(:webauftritt_may).reference], report.entries.collect(&:reference)
    end

    test 'filter by department' do
      report(department_id: departments(:devtwo).id)

      assert_equal [@invc1.reference, @invc2.reference].sort, report.entries.collect(&:reference).sort
    end

    test 'filter by kind' do
      report(kind_id: order_kinds(:projekt).id)

      assert_equal [@invc1.reference, @invc2.reference, invoices(:webauftritt_may).reference].sort, report.entries.collect(&:reference).sort
    end

    test 'filter by client' do
      report(client_work_item_id: clients(:puzzle).work_item_id)

      assert_equal [@invc1.reference, @invc2.reference].sort, report.entries.collect(&:reference).sort
    end

    test 'filter by start date' do
      report(period: Period.new(Date.new(2020, 6, 13), nil))

      assert_equal [@invc1.reference, @invc2.reference].sort, report.entries.collect(&:reference).sort
    end

    test 'filter by end date' do
      report(period: Period.new(nil, Date.new(2024, 12, 12)))

      assert_equal [@invc1.reference, invoices(:webauftritt_may).reference].sort, report.entries.collect(&:reference).sort
    end

    test 'filter by period' do
      report(period: Period.new(Date.new(2015, 6, 13), Date.new(2024, 12, 12)))

      assert_equal [@invc1.reference, invoices(:webauftritt_may).reference].sort, report.entries.collect(&:reference).sort
    end

    ### sorting

    test 'sort by reference desc' do
      report(sort: 'reference', sort_dir: 'desc')

      assert_equal [invoices(:webauftritt_may).reference, @invc2.reference, @invc1.reference], report.entries.collect(&:reference)
    end

    test 'sort by client desc' do
      report(sort: 'client', sort_dir: 'desc')

      assert_equal [invoices(:webauftritt_may).reference, @invc1.reference, @invc2.reference], report.entries.collect(&:reference)
    end

    test 'sort by billing_date desc' do
      report(sort: 'billing_date', sort_dir: 'desc')

      assert_equal [@invc2.reference, @invc1.reference, invoices(:webauftritt_may).reference], report.entries.collect(&:reference)
    end

    test 'sort by due_date desc' do
      report(sort: 'due_date', sort_dir: 'desc')

      assert_equal [@invc2.reference, @invc1.reference, invoices(:webauftritt_may).reference], report.entries.collect(&:reference)
    end

    test 'sort by total_amount desc' do
      report(sort: 'total_amount', sort_dir: 'desc')

      assert_equal [invoices(:webauftritt_may).reference, @invc2.reference, @invc1.reference], report.entries.collect(&:reference)
    end

    test 'sort by total_hours desc' do
      report(sort: 'total_hours', sort_dir: 'desc')

      assert_equal [invoices(:webauftritt_may).reference, @invc2.reference, @invc1.reference], report.entries.collect(&:reference)
    end

    test 'sort by status desc' do
      report(sort: 'status', sort_dir: 'desc')

      assert_equal [@invc1.reference, invoices(:webauftritt_may).reference, @invc2.reference], report.entries.collect(&:reference)
    end

    test 'sort by department desc' do
      report(sort: 'department', sort_dir: 'desc')

      assert_equal [@invc1.reference, @invc2.reference, invoices(:webauftritt_may).reference], report.entries.collect(&:reference)
    end

    test 'sort by responsible desc' do
      report(sort: 'responsible', sort_dir: 'desc')

      assert_equal [@invc1.reference, @invc2.reference, invoices(:webauftritt_may).reference], report.entries.collect(&:reference)
    end

    ### calculating

    test 'it counts orders' do
      assert_equal 'Total (3)', report.total.to_s
    end

    test 'it counts filtered orders' do
      assert_equal 'Total (1)', report(status: 'paid').total.to_s
    end

    test 'it counts filtered not closed orders' do
      assert_equal 'Total (2)', report(client_work_item_id: clients(:puzzle).work_item_id).total.to_s
    end

    test '#total_amount is sum of all invoices' do
      assert_equal report.total.total_amount, report.entries.sum(&:total_amount)
    end

    test '#total_hours is sum of all invoices' do
      assert_equal report.total.total_hours, report.entries.sum(&:total_hours)
    end

    private

    def report(params = {})
      period = params.delete(:period) || Period.new(nil, nil)
      @report ||= Invoice::Report.new(period, params)
    end

    def create_invoices
      Fabricate(:contract, order: orders(:hitobito_demo))
      Fabricate(:ordertime, work_item: work_items(:hitobito_demo_app), employee: employees(:pascal), hours: 10,
                            work_date: '2022-01-01')
      Fabricate(:ordertime, work_item: work_items(:hitobito_demo_app), employee: employees(:pascal), hours: 2,
                            work_date: '2022-01-01')
      Fabricate(:ordertime, work_item: work_items(:hitobito_demo_app), employee: employees(:pascal), hours: 2,
                            work_date: '2022-01-01', billable: false)
      Fabricate(:ordertime, work_item: work_items(:hitobito_demo_app), employee: employees(:mark), hours: 20,
                            work_date: '2011-12-01')
      @invc1 = Fabricate(:invoice, order: orders(:hitobito_demo), work_items: work_items(:hitobito_demo_app, :hitobito_demo_site),
                                   employees: [employees(:pascal)], billing_date: '2024-10-01', due_date: '2024-12-31', status: 'paid')
      @invc2 = Fabricate(:invoice, order: orders(:hitobito_demo), work_items: [work_items(:hitobito_demo_app)], employees: [employees(:mark)],
                                   billing_date: '2025-02-01', due_date: '2025-04-31')
    end
  end
end
