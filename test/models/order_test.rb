# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# {{{
# == Schema Information
#
# Table name: orders
#
#  id                 :integer          not null, primary key
#  closed_at          :date
#  committed_at       :date
#  completed_at       :date
#  crm_key            :string
#  major_chance_value :integer
#  major_risk_value   :integer
#  created_at         :datetime
#  updated_at         :datetime
#  billing_address_id :integer
#  contract_id        :integer
#  department_id      :integer
#  kind_id            :integer
#  responsible_id     :integer
#  status_id          :integer
#  work_item_id       :integer          not null
#
# Indexes
#
#  index_orders_on_billing_address_id  (billing_address_id)
#  index_orders_on_contract_id         (contract_id)
#  index_orders_on_department_id       (department_id)
#  index_orders_on_kind_id             (kind_id)
#  index_orders_on_responsible_id      (responsible_id)
#  index_orders_on_status_id           (status_id)
#  index_orders_on_work_item_id        (work_item_id)
#
# }}}

require 'test_helper'

class OrderTest < ActiveSupport::TestCase
  test 'order without client is not valid' do
    order = Fabricate(:order)
    order.build_work_item(name: 'New Order', shortname: 'NEOR')

    assert_not order.valid?
  end

  test 'order with client is valid' do
    order = Fabricate.build(:order)
    _item = order.build_work_item(name: 'New Order', shortname: 'NEOR', parent_id: work_items(:puzzle).id)

    assert_predicate order, :valid?, order.errors.full_messages.join(', ')
    assert_equal clients(:puzzle), order.client
    order.save!
    order = Order.find(order.id)

    assert_equal clients(:puzzle), order.client
  end

  test 'order with category and client is valid' do
    order = Fabricate.build(:order)
    cat = Fabricate(:work_item, name: 'New Cat', shortname: 'NECA', parent_id: work_items(:puzzle).id)
    _item = order.build_work_item(name: 'New Order', shortname: 'NEOR', parent_id: cat.id)

    assert_predicate order, :valid?, order.errors.full_messages.join(', ')
    assert_equal clients(:puzzle), order.client
    order.save!
    order = Order.find(order.id)

    assert_equal clients(:puzzle), order.client
  end

  test 'order is created with status' do
    order = Fabricate(:order)

    assert_equal OrderStatus.defaults.first, order.status
  end

  test 'created order comes with order targets' do
    order = Fabricate(:order)
    scopes = TargetScope.all

    assert_operator scopes.size, :>, 0
    assert_equal scopes.to_set, order.targets.to_set(&:target_scope)
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

  test 'closed status is propagated to all descendants' do
    order = orders(:hitobito_demo)
    order.status = order_statuses(:abgeschlossen)
    order.save!

    assert_equal [true], order.work_item.self_and_descendants.collect(&:closed).uniq

    order.status = order_statuses(:bearbeitung)
    order.save!

    assert_equal [false], order.work_item.self_and_descendants.collect(&:closed).uniq
  end

  test 'non-closed status is propagated to all descendants according to accounting posts' do
    order = orders(:hitobito_demo)
    order.status = order_statuses(:abgeschlossen)
    order.save!

    accounting_posts(:hitobito_demo_site).update!(closed: true)

    assert_equal [true], order.work_item.self_and_descendants.collect(&:closed).uniq

    order.status = order_statuses(:bearbeitung)
    order.save!

    assert_not work_items(:hitobito_demo).closed
    assert work_items(:hitobito_demo_site).closed
    assert_not work_items(:hitobito_demo_app).closed
  end

  test 'default_billing_address_id is nil when last_billing_address is blank' do
    order = Fabricate(:order)
    order.billing_address = nil

    assert_nil order.default_billing_address_id
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

  test '#major_risk' do
    assert_nil Order.new.major_risk
    assert_equal :low, Order.new(major_risk_value: 1).major_risk
    assert_equal :low, Order.new(major_risk_value: 2).major_risk
    assert_equal :medium, Order.new(major_risk_value: 3).major_risk
    assert_equal :medium, Order.new(major_risk_value: 4).major_risk
    assert_equal :medium, Order.new(major_risk_value: 6).major_risk
    assert_equal :high, Order.new(major_risk_value: 8).major_risk
    assert_equal :high, Order.new(major_risk_value: 9).major_risk
    assert_equal :high, Order.new(major_risk_value: 12).major_risk
    assert_equal :high, Order.new(major_risk_value: 16).major_risk
  end

  test '#major_chance' do
    assert_nil Order.new.major_chance
    assert_equal :low, Order.new(major_chance_value: 1).major_chance
    assert_equal :low, Order.new(major_chance_value: 2).major_chance
    assert_equal :medium, Order.new(major_chance_value: 3).major_chance
    assert_equal :medium, Order.new(major_chance_value: 4).major_chance
    assert_equal :medium, Order.new(major_chance_value: 6).major_chance
    assert_equal :high, Order.new(major_chance_value: 8).major_chance
    assert_equal :high, Order.new(major_chance_value: 9).major_chance
    assert_equal :high, Order.new(major_chance_value: 12).major_chance
    assert_equal :high, Order.new(major_chance_value: 16).major_chance
  end
end
