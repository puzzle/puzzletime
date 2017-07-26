# encoding: utf-8

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


# coding: utf-8
require 'test_helper'

class ExtendedCapacityReportTest < ActiveSupport::TestCase
  setup :create_worktimes

  test 'renders employee capacity data as CSV' do
    csv = ExtendedCapacityReport.new(period).to_csv
    data = CSV.parse(csv)
    header = data.first
    rows = data.select { |row| row.first == 'PZ' }

    assert_equal 4, rows.length

    summary = rows.first

    assert_equal 'Beschäftigungsgrad (%)', header[2]
    assert_equal '100.0', summary[2]

    assert_equal 'Projekte Total (h)', header[11]
    assert_equal '21.0', summary[11]

    assert_equal 'Kunden-Projekte Total (h)', header[14]
    assert_equal '13.0', summary[14]

    assert_equal 'Kunden-Projekte Total verrechenbar (h)', header[16]
    assert_equal '6.0', summary[16]

    assert_equal 'Kunden-Projekte Total nicht verrechenbar (h)', header[18]
    assert_equal '7.0', summary[18]

    assert_equal 'Interne Projekte Total (h)', header[20]
    assert_equal '8.0', summary[20]

    webauftritt = rows.second
    shop = rows.third
    ptime = rows.fourth

    assert_equal 'Auftrag Organisationseinheit', header[1]
    assert_equal 'devone', webauftritt[1]
    assert_equal 'devone', shop[1]
    assert_equal 'devone', ptime[1]

    assert_equal 'Projektkürzel', header[8]
    assert_equal 'STOP-WEB', webauftritt[8]
    assert_equal 'STOP-SHP', shop[8]
    assert_equal 'PITC-PT', ptime[8]

    assert_equal 'Projekte Total - Detail (h)', header[12]
    assert_equal '3.0', webauftritt[12]
    assert_equal '10.0', shop[12]
    assert_equal '8.0', ptime[12]

    assert_equal 'Kunden-Projekte Total - Detail (h)', header[15]
    assert_equal '3.0', webauftritt[15]
    assert_equal '10.0', shop[15]
    assert_equal '0', ptime[15]

    assert_equal 'Kunden-Projekte Total verrechenbar - Detail (h)', header[17]
    assert_equal '2.0', webauftritt[17]
    assert_equal '4.0', shop[17]
    assert_equal '0', ptime[17]

    assert_equal 'Kunden-Projekte Total nicht verrechenbar - Detail (h)', header[19]
    assert_equal '1.0', webauftritt[19]
    assert_equal '6.0', shop[19]
    assert_equal '0', ptime[19]

    assert_equal 'Interne Projekte Total - Detail (h)', header[21]
    assert_equal '0', webauftritt[21]
    assert_equal '0', shop[21]
    assert_equal '8.0', ptime[21]
  end

  private

  def create_worktimes
    employee.employments.create(start_date: period.start_date, percent: 100)

    # billable project
    create_time(work_items(:webauftritt), 2, true)
    create_time(work_items(:webauftritt), 1, false)

    # non billable project
    shop = WorkItem.create!(parent: work_items(:swisstopo),
                            name: 'Shop',
                            shortname: 'SHP',
                            leaf: true)
    order = orders(:webauftritt).dup
    order.work_item = shop
    order.save!
    shop.create_accounting_post!(portfolio_item: portfolio_items(:web),
                                 service: services(:software),
                                 offered_rate: 0,
                                 billable: false)
    create_time(shop, 6, false)
    create_time(shop, 4, true)

    # internal project
    create_time(work_items(:puzzletime), 5, false)
    create_time(work_items(:puzzletime), 3, true)
  end

  def create_time(work_item, hours, billable)
    Fabricate(:ordertime,
              work_item: work_item,
              employee: employee,
              work_date: Date.parse('2017-01-23'),
              hours: hours,
              billable: billable)
  end

  def employee
    @employee ||= employees(:pascal)
  end

  def period
    @period ||= Period.month_for(Date.parse('2017-01-01'))
  end
end
