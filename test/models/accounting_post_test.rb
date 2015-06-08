# == Schema Information
#
# Table name: accounting_posts
#
#  id                     :integer          not null, primary key
#  work_item_id           :integer          not null
#  portfolio_item_id      :integer
#  reference              :string(255)
#  offered_hours          :integer
#  offered_rate           :decimal(12, 2)
#  offered_total          :decimal(12, 2)
#  discount_percent       :integer
#  discount_fixed         :integer
#  remaining_hours        :integer
#  billable               :boolean          default(TRUE), not null
#  description_required   :boolean          default(FALSE), not null
#  ticket_required        :boolean          default(FALSE), not null
#  closed                 :boolean          default(FALSE), not null
#  from_to_times_required :boolean          default(FALSE), not null
#

require 'test_helper'

class AccountingPostTest < ActiveSupport::TestCase

  test 'order work item with accounting post is moved when creating new accounting post' do
    post = accounting_posts(:webauftritt)
    order = post.order
    order.update!(status: order_statuses(:abgeschlossen))
    assert_equal post.work_item_id, order.work_item_id
    fresh = nil
    assert_difference('WorkItem.count', 2) do
      fresh = AccountingPost.create!(
                work_item: WorkItem.new(name: 'Foo', shortname: 'FOO', parent: post.work_item),
                portfolio_item: PortfolioItem.first,
                offered_rate: 150)
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

  private

  def post
    accounting_posts(:hitobito_demo_app)
  end

end
