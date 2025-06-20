# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'

module Billing
  class ReportTest < ActiveSupport::TestCase
    ### filtering

    test 'contains all orders that have > 0 hours of unbilled worktimes or open flatrates' do
      assert_equal 4, report.entries.size
    end

    test 'filter by status' do
      report(status_id: order_statuses(:abgeschlossen))

      assert_equal [orders(:allgemein)], report.entries.collect(&:order)
    end

    test 'filter by responsible' do
      report(responsible_id: employees(:long_time_john).id)

      assert_equal [orders(:webauftritt)], report.entries.collect(&:order)
    end

    test 'filter by department' do
      report(department_id: departments(:devtwo).id)

      assert_equal [orders(:hitobito_demo)], report.entries.collect(&:order)
    end

    test 'filter by kind' do
      report(kind_id: order_kinds(:projekt).id)

      assert_equal orders(:hitobito_demo, :webauftritt), report.entries.collect(&:order)
    end

    test 'filter by responsible and department' do
      report(responsible_id: employees(:lucien).id, department_id: departments(:devone).id)

      assert_equal [orders(:puzzletime)], report.entries.collect(&:order)
    end

    test 'filter too restrictive' do
      report(kind_id: order_kinds(:mandat).id,
             department_id: departments(:sys).id,
             status_id: order_statuses(:bearbeitung).id)

      assert_empty report.entries
    end

    test 'filter by client' do
      report(client_work_item_id: work_items(:puzzle).id)

      # hitobito_demo appears, since it has open flatrates
      assert_equal orders(:allgemein, :hitobito_demo, :puzzletime), report.entries.collect(&:order)
    end

    test 'filter by start date' do
      report(period: Period.new(Date.new(2006, 12, 11), nil))

      # hitobito_demo appears, since it has open flatrates
      assert_equal orders(:hitobito_demo, :webauftritt), report.entries.collect(&:order)
    end

    test 'filter by end date' do
      report(period: Period.new(nil, Date.new(2006, 12, 1)))

      assert_equal [orders(:allgemein)], report.entries.collect(&:order)
    end

    test 'filter by period' do
      report(period: Period.new(Date.new(2006, 12, 4), Date.new(2006, 12, 6)))

      assert_equal [orders(:allgemein)], report.entries.collect(&:order)
    end

    ### sorting

    test 'sort by client' do
      report(sort: 'client', sort_dir: 'desc')

      # hitobito_demo appears, since it has open flatrates
      assert_equal orders(:allgemein, :hitobito_demo, :puzzletime, :webauftritt), report.entries.collect(&:order)
    end

    test 'sort by target time' do
      report(sort: "target_scope_#{target_scopes(:time).id}", sort_dir: 'desc')

      # hitobito_demo appears, since it has open flatrates
      assert_equal orders(:allgemein, :hitobito_demo, :puzzletime, :webauftritt), report.entries.collect(&:order)
    end

    test 'sort by not_billed_amount' do
      report(sort: 'not_billed_amount', sort_dir: 'desc')

      # hitobito_demo is last since unpaid amount (from worktimes) is 0
      assert_equal orders(:webauftritt, :puzzletime, :allgemein, :hitobito_demo), report.entries.collect(&:order)
    end

    ### calculating

    test 'it counts orders' do
      assert_equal 'Total (4)', report.total.to_s
    end

    test 'billable_amount is always sum of not_billed_amount and billed_amount' do
      report.entries.each do |e|
        assert_equal e.not_billed_amount + e.billed_amount, e.billable_amount
      end
    end

    test 'correctly reflect unbilled hours' do
      order = orders(:webauftritt)
      Fabricate(:contract, order:)
      Fabricate(:ordertime, work_item: work_items(:webauftritt), employee: employees(:pascal), hours: 10,
                            work_date: '2020-10-10')

      Fabricate(:invoice, order:, work_items: [work_items(:webauftritt)], employees: [employees(:pascal)],
                          period_from: '2020-10-01', period_to: '2020-10-20', billing_date: '2020-12-01')

      entry_ptime = report.entries.find { |e| e.order == orders(:puzzletime) }
      entry_webauftritt = report.entries.find { |e| e.order == orders(:webauftritt) }

      assert_in_delta 24, entry_ptime.not_billed_amount
      assert_in_delta 2520, entry_webauftritt.not_billed_amount
      assert_in_delta 1400, entry_webauftritt.billed_amount
    end

    private

    def report(params = {})
      period = params.delete(:period) || Period.new(nil, nil)
      @report ||= Billing::Report.new(period, params)
    end
  end
end
