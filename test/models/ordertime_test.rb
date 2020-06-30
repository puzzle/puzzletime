#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# == Schema Information
#
# Table name: worktimes
#
#  id              :integer          not null, primary key
#  absence_id      :integer
#  employee_id     :integer
#  report_type     :string(255)      not null
#  work_date       :date             not null
#  hours           :float
#  from_start_time :time
#  to_end_time     :time
#  description     :text
#  billable        :boolean          default(TRUE)
#  type            :string(255)
#  ticket          :string(255)
#  work_item_id    :integer
#  invoice_id      :integer
#

require 'test_helper'

class OrdertimeTest < ActiveSupport::TestCase
  test 'closed worktimes may not change anymore' do
    t = Ordertime.create!(employee: employees(:pascal),
                          work_date: '2015-10-10',
                          hours: 2,
                          work_item: work_items(:webauftritt),
                          report_type: 'absolute_day')
    work_items(:webauftritt).update!(closed: true)
    t.reload
    t.work_date = '2015-08-31'
    assert_not_valid t, :base
  end

  test 'closed worktimes may not change work_item anymore' do
    t = Ordertime.create!(employee: employees(:pascal),
                          work_date: '2015-10-10',
                          hours: 2,
                          work_item: work_items(:webauftritt),
                          report_type: 'absolute_day')
    work_items(:webauftritt).update!(closed: true)
    t.reload
    t.work_item = work_items(:hitobito_demo_app)
    assert_not_valid t, :base
  end

  test 'worktimes may not change to closed work_item' do
    t = Ordertime.create!(employee: employees(:pascal),
                          work_date: '2015-10-10',
                          hours: 2,
                          work_item: work_items(:webauftritt),
                          report_type: 'absolute_day')
    work_items(:hitobito_demo_app).update!(closed: true)
    t.work_item = work_items(:hitobito_demo_app)
    assert_not_valid t, :base
  end

  test 'worktime times must be 00:00-23:59' do
    t = Ordertime.create(employee: employees(:pascal),
      work_date:       '2015-10-10',
      from_start_time: '00:00',
      to_end_time:     '24:00',
      work_item:       work_items(:webauftritt),
      report_type:     'start_stop_day')

    refute t.valid?, t.errors.details[:to_end_time].join(', ')
  end

  test '#invoice_sent_or_paid?' do
    t = Ordertime.new
    assert !t.invoice_sent_or_paid?

    [['draft', false],
     ['sent', true],
     ['paid', true],
     ['partially_paid', true],
     ['deleted', false]].each do |status, result|
      t.invoice = Invoice.new(status: status)
      assert_equal result, t.invoice_sent_or_paid?, "Status '#{status}', result should be #{result}"
    end
  end
end
