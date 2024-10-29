# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# {{{
# == Schema Information
#
# Table name: worktimes
#
#  id                :integer          not null, primary key
#  billable          :boolean          default(TRUE)
#  description       :text
#  from_start_time   :time
#  hours             :float
#  meal_compensation :boolean          default(FALSE), not null
#  report_type       :string(255)      not null
#  ticket            :string(255)
#  to_end_time       :time
#  type              :string(255)
#  work_date         :date             not null
#  absence_id        :integer
#  employee_id       :integer
#  invoice_id        :integer
#  work_item_id      :integer
#
# Indexes
#
#  index_worktimes_on_invoice_id  (invoice_id)
#  worktimes_absences             (absence_id,employee_id,work_date)
#  worktimes_employees            (employee_id,work_date)
#  worktimes_work_items           (work_item_id,employee_id,work_date)
#
# Foreign Keys
#
#  fk_times_absences   (absence_id => absences.id) ON DELETE => cascade
#  fk_times_employees  (employee_id => employees.id) ON DELETE => cascade
#
# }}}

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
                         work_date: '2015-10-10',
                         from_start_time: '00:00',
                         to_end_time: '24:00',
                         work_item: work_items(:webauftritt),
                         report_type: 'start_stop_day')

    assert_not_predicate t, :valid?, t.errors.details[:to_end_time].join(', ')
  end

  test '#invoice_sent_or_paid?' do
    t = Ordertime.new

    assert_not t.invoice_sent_or_paid?

    [['draft', false],
     ['sent', true],
     ['paid', true],
     ['partially_paid', true],
     ['deleted', false]].each do |status, result|
      t.invoice = Invoice.new(status:)

      assert_equal result, t.invoice_sent_or_paid?, "Status '#{status}', result should be #{result}"
    end
  end
end
