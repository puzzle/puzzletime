#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# == Schema Information
#
# Table name: accounting_posts
#
#  id                     :integer          not null, primary key
#  work_item_id           :integer          not null
#  portfolio_item_id      :integer
#  offered_hours          :float
#  offered_rate           :decimal(12, 2)
#  offered_total          :decimal(12, 2)
#  remaining_hours        :integer
#  billable               :boolean          default(TRUE), not null
#  description_required   :boolean          default(FALSE), not null
#  ticket_required        :boolean          default(FALSE), not null
#  closed                 :boolean          default(FALSE), not null
#  from_to_times_required :boolean          default(FALSE), not null
#  service_id             :integer
#

require 'test_helper'

class AccountingPostTest < ActiveSupport::TestCase
  test 'order work item with accounting post is moved when creating new accounting post' do
    post = accounting_posts(:webauftritt)
    order = post.order
    order.update!(status: order_statuses(:abgeschlossen))

    assert_equal post.work_item_id, order.work_item_id
    assert_equal true, post.work_item.closed
    fresh = nil
    assert_difference('WorkItem.count', 2) do
      fresh = AccountingPost.create!(
        work_item: WorkItem.new(name: 'Foo', shortname: 'FOO', parent: post.work_item),
        portfolio_item: PortfolioItem.first,
        service: Service.first,
        offered_rate: 150
      )
    end
    post.reload
    fresh.reload

    assert_not_equal post.work_item_id, order.work_item_id
    assert_equal post.work_item_id, worktimes(:wt_pz_webauftritt).work_item_id
    assert_equal true, fresh.work_item.leaf
    assert_equal true, post.work_item.leaf
    assert_equal true, fresh.work_item.closed
    assert_equal true, post.work_item.closed
  end

  test 'creating new accounting post when order workitem is invalid sets flash message' do
    post = accounting_posts(:webauftritt)
    post.update_column(:offered_rate, nil)

    refute_predicate post.reload, :valid?
    order = post.order

    assert_equal post.work_item_id, order.work_item_id
    assert_no_difference('WorkItem.count') do
      fresh = AccountingPost.create(
        work_item: WorkItem.new(name: 'Foo', shortname: 'FOO', parent: post.work_item),
        portfolio_item: PortfolioItem.first,
        service: Service.first,
        offered_rate: 150
      )

      post.reload

      assert_equal post.work_item_id, order.work_item_id
      assert_error_message fresh, :base, /Bestehende Buchungsposition ist ungültig/
    end
  end

  test 'opening post with closed order does not open work items' do
    closed = OrderStatus.where(closed: true).first
    post.order.update!(status: closed)

    assert_equal true, post.work_item.reload.closed

    post.update!(closed: true)
    post.update!(closed: false)

    assert_equal true, post.work_item.reload.closed

    opened = OrderStatus.where(closed: false).first
    post.order.update!(status: opened)

    assert_equal false, post.work_item.reload.closed
  end

  test 'opening order with closed post does not open work items' do
    closed = OrderStatus.where(closed: true).first
    post.order.update!(status: closed)
    post.update!(closed: true)

    opened = OrderStatus.where(closed: false).first
    post.order.update!(status: opened)

    assert_equal true, post.work_item.reload.closed

    post.update!(closed: false)

    assert_equal false, post.work_item.reload.closed

    post.order.update!(status: closed)

    assert_equal true, post.work_item.reload.closed
  end

  test 'destroying accounting post destroys work item' do
    assert_difference('AccountingPost.count', -1) do
      assert_difference('WorkItem.count', -1) do
        post.destroy
      end
    end
  end

  test 'offered total is derived from hours' do
    post.update!(offered_rate: 100, offered_hours: 10, offered_total: nil)

    assert_equal 10, post.offered_hours
    assert_equal 1000, post.offered_total
  end

  test 'offered hours is derived from total' do
    post.update!(offered_rate: 100, offered_hours: ' ', offered_total: 1000)

    assert_equal 10, post.offered_hours
    assert_equal 1000, post.offered_total
  end

  test 'offered hours and total is not derived if given' do
    post.update!(offered_rate: 100, offered_hours: 5, offered_total: 1000)

    assert_equal 5, post.offered_hours
    assert_equal 1000, post.offered_total
  end

  test 'moves work times and plannings on work item change' do
    employee = Fabricate(:employee)
    order = Fabricate(:order)
    accounting_post = Fabricate(:accounting_post, work_item: order.work_item)
    5.times do |i|
      Fabricate(:planning, work_item: order.work_item, employee:) do
        date { Date.new(2017, 12, 18) + i }
      end
    end
    Fabricate.times(10, :ordertime, work_item: order.work_item,
                                    employee:)

    assert_equal order.work_item, accounting_post.work_item

    assert_equal 5, accounting_post.plannings.count
    assert_equal 10, accounting_post.worktimes.count

    new_work_item = Fabricate(:work_item, parent_id: order.work_item.id)
    Fabricate(:accounting_post, work_item: new_work_item)

    order.reload
    accounting_post.reload

    assert_not_equal order.work_item, accounting_post.work_item

    plannings = order.work_item.plannings.select do |p|
      p.work_item_id == order.work_item.id
    end

    assert_equal 0, plannings.size

    worktimes = order.work_item.worktimes.select do |t|
      t.work_item_id == order.work_item.id
    end

    assert_equal 0, worktimes.size

    assert_equal 5, accounting_post.plannings.count
    assert_equal 10, accounting_post.worktimes.count
  end

  private

  def post
    accounting_posts(:hitobito_demo_app)
  end
end
