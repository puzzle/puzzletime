# == Schema Information
#
# Table name: orders
#
#  id                 :integer          not null, primary key
#  work_item_id       :integer          not null
#  kind_id            :integer
#  responsible_id     :integer
#  status_id          :integer
#  department_id      :integer
#  contract_id        :integer
#  billing_address_id :integer
#  crm_key            :string(255)
#  created_at         :datetime
#  updated_at         :datetime
#

require 'test_helper'

class OrderTest < ActiveSupport::TestCase

  test 'order without client is not valid' do
    order = Fabricate(:order)
    item = order.build_work_item(name: 'New Order', shortname: 'NEOR')
    assert !order.valid?
  end

  test 'order with client is valid' do
    order = Fabricate.build(:order)
    item = order.build_work_item(name: 'New Order', shortname: 'NEOR', parent_id: work_items(:puzzle).id)
    assert order.valid?, order.errors.full_messages.join(', ')
    assert_equal clients(:puzzle), order.client
    order.save!
    order = Order.find(order.id)
    assert_equal clients(:puzzle), order.client
  end

  test 'order with category and client is valid' do
    order = Fabricate.build(:order)
    cat = order.create_work_item!(name: 'New Cat', shortname: 'NECA', parent_id: work_items(:puzzle).id)
    item = order.build_work_item(name: 'New Order', shortname: 'NEOR', parent_id: cat.id)
    assert order.valid?, order.errors.full_messages.join(', ')
    assert_equal clients(:puzzle), order.client
    order.save!
    order = Order.find(order.id)
    assert_equal clients(:puzzle), order.client
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

  test 'default_billing_address_id is nil when last_billing_address is blank' do
    order = Fabricate(:order)
    order.billing_address = nil
    assert_equal(nil, order.default_billing_address_id)
  end

  test 'default_billing_address_id from client when last_billing_address is blank' do
    order = Fabricate(:order, work_item: Fabricate(:work_item, parent: clients(:swisstopo).work_item))
    order.billing_address = nil
    assert_equal(billing_addresses(:swisstopo).id, order.default_billing_address_id)
  end

  test 'default_billing_address when last_billing_address is set' do
    order = Fabricate(:order, work_item: Fabricate(:work_item, parent: clients(:swisstopo).work_item))
    [billing_addresses(:swisstopo), billing_addresses(:swisstopo_2)].each do |address|
      order.billing_address = address
      assert_equal(address.id, order.default_billing_address_id)
    end
  end
end
