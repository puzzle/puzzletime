#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'

class Order::Report::BITest < ActiveSupport::TestCase
  test 'collects stats' do
    stats = Order::Report::BI.new.stats

    ptime = stats.find { |stat| stat.dig(:tags, :name) == 'PuzzleTime' }

    assert_equal('order_report', ptime[:name])
    assert_equal(
      {
        client: 'Puzzle ITC',
        category: '',
        name: 'PuzzleTime',
        status: 'In Bearbeitung',
        department: 'devone',
        target_schedule: 'green',
        target_budget: 'orange',
        target_quality: 'green'
      },
      ptime[:tags]
    )
    assert_equal(44, ptime.dig(:fields, :billability))
    assert_equal(
      %i[
        offered_amount
        supplied_amount
        billable_amount
        billed_amount
        billability
        offered_rate
        billed_rate
        average_rate
      ],
      ptime[:fields].keys
    )
  end

  private

  def report(params = {})
    period = params.delete(:period) || Period.new(nil, nil)
    @report ||= Order::Report.new(period, params)
  end
end
