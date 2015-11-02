# encoding: utf-8
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

  test 'committed worktimes may not be created' do
    e = employees(:pascal)
    e.update!(committed_worktimes_at: '2015-08-31')
    t = Ordertime.new(employee: e,
                      work_date: '2015-08-31',
                      hours: 2,
                      work_item: work_items(:webauftritt),
                      report_type: 'absolute_day')
    assert_not_valid t, :work_date
  end

  test 'uncommitted worktimes may be created' do
    e = employees(:pascal)
    e.update!(committed_worktimes_at: '2015-08-31')
    t = Ordertime.new(employee: e,
                      work_date: '2015-09-01',
                      hours: 2,
                      work_item: work_items(:webauftritt),
                      report_type: 'absolute_day')
    assert_valid t
  end

  test 'committed worktimes may not be updated' do
    e = employees(:pascal)
    t = Ordertime.create!(employee: e,
                          work_date: '2015-08-31',
                          hours: 2,
                          work_item: work_items(:webauftritt),
                          report_type: 'absolute_day')
    e.update!(committed_worktimes_at: '2015-09-30')
    t.reload
    t.hours = 3
    assert_not_valid t, :work_date
  end

  test 'committed worktimes may not change work date' do
    e = employees(:pascal)
    t = Ordertime.create!(employee: e,
                          work_date: '2015-08-31',
                          hours: 2,
                          work_item: work_items(:webauftritt),
                          report_type: 'absolute_day')
    e.update!(committed_worktimes_at: '2015-09-30')
    t.reload
    t.work_date = '2015-10-10'
    assert_not_valid t, :work_date
  end

  test 'committed worktimes may not be destroyed' do
    e = employees(:pascal)
    t = Ordertime.create!(employee: e,
                          work_date: '2015-08-31',
                          hours: 2,
                          work_item: work_items(:webauftritt),
                          report_type: 'absolute_day')
    e.update!(committed_worktimes_at: '2015-09-30')
    t.reload
    assert_equal false, t.destroy
    assert_match /September 2015 wurden freigegeben/, t.errors.full_messages.join
  end
end
