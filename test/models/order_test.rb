require 'test_helper'

class OrderTest < ActiveSupport::TestCase

  test 'order without client is not valid' do
    order = Fabricate(:order)
    item = order.build_work_item(name: 'New Order', shortname: 'NEOR')
    assert !order.valid?
  end

  test 'order with client is valid' do
    order = Fabricate(:order)
    item = order.build_work_item(name: 'New Order', shortname: 'NEOR', parent_id: work_items(:puzzle).id)
    assert order.valid?, order.errors.full_messages.join(', ')
  end

  test 'order is created with status' do
    order = Fabricate(:order)
    assert_equal OrderStatus.list.first, order.status
  end

  test 'created order comes with order targets' do
    order = Fabricate(:order)
    scopes = TargetScope.all
    assert scopes.size > 0
    assert_equal scopes.to_set, order.targets.collect(&:target_scope).to_set
  end

  test 'accounting posts on lower level are accessible through work items' do
    order = orders(:hitobito_demo)
    assert_equal accounting_posts(:hitobito_demo_app, :hitobito_demo_site).to_set, order.accounting_posts.to_set
  end

  test 'accounting post on same level is accessible through work items' do
    order = orders(:puzzletime)
    assert_equal [accounting_posts(:puzzletime)], order.accounting_posts
  end

  test 'client is accessible through work items' do
    order = orders(:hitobito_demo)
    assert_equal clients(:puzzle), order.client
  end

  test 'closed status is propagated to all leaves' do
    order = orders(:hitobito_demo)
    order.status = order_statuses(:abgeschlossen)
    order.save!

    assert_equal [true], order.work_item.self_and_descendants.leaves.collect(&:closed).uniq

    order.status = order_statuses(:bearbeitung)
    order.save!

    assert_equal [false], order.work_item.self_and_descendants.leaves.collect(&:closed).uniq
  end

  test 'non-closed status is propagated to all leaves according to accounting posts' do
    order = orders(:hitobito_demo)
    order.status = order_statuses(:abgeschlossen)
    order.save!

    accounting_posts(:hitobito_demo_site).update!(closed: true)

    assert_equal [true], order.work_item.self_and_descendants.leaves.collect(&:closed).uniq

    order.status = order_statuses(:bearbeitung)
    order.save!

    assert work_items(:hitobito_demo_site).closed
    assert !work_items(:hitobito_demo_app).closed
  end

end
