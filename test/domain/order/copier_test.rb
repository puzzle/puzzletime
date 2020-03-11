#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'

class Order::CopierTest < ActiveSupport::TestCase
  test 'copy does not save anything' do
    assert_no_difference('WorkItem.count') do
      assert_no_difference('Order.count') do
        assert_no_difference('OrderContact.count') do
          assert_no_difference('OrderTeamMember.count') do
            assert_no_difference('Contract.count') do
              assert_no_difference('AccountingPost.count') do
                copier = Order::Copier.new(order)
                copy = copier.copy
                copier.copy_associations(copy)
              end
            end
          end
        end
      end
    end
  end

  test 'saving copy with associations creates all objects with children' do
    order.order_team_members.create!(employee: employees(:pascal), comment: 'Coder')
    order.order_team_members.create!(employee: employees(:lucien), comment: 'PL')
    order.order_contacts.create!(contact: contacts(:puzzle_rava), comment: 'BL')
    order.create_contract!(number: 'hito1234', start_date: '2005-01-01', end_date: '2020-07-30')

    assert_difference('WorkItem.count', 3) do
      assert_difference('Order.count', 1) do
        assert_difference('OrderContact.count', 1) do
          assert_difference('OrderTeamMember.count', 2) do
            assert_difference('Contract.count', 1) do
              assert_difference('AccountingPost.count', 2) do
                assert_difference('OrderTarget.count', 3) do
                  copier = Order::Copier.new(order)
                  copy = copier.copy
                  copy.work_item.name = 'Other name'
                  copy.work_item.shortname = 'ONZ'
                  copier.copy_associations(copy)
                  copy.save!
                end
              end
            end
          end
        end
      end
    end
  end

  test 'saving copy with associations creates all objects without children' do
    assert_difference('WorkItem.count', 1) do
      assert_difference('Order.count', 1) do
        assert_no_difference('OrderContact.count') do
          assert_no_difference('OrderTeamMember.count') do
            assert_difference('Contract.count', 1) do
              assert_difference('AccountingPost.count', 1) do
                order = orders(:webauftritt)
                copier = Order::Copier.new(order)
                copy = copier.copy
                copy.work_item.name = 'Other name'
                copy.work_item.shortname = 'ONZ'
                copier.copy_associations(copy)
                copy.save!
              end
            end
          end
        end
      end
    end
  end

  test 'copies most direct attributes' do
    assert_nil copy.id
    assert_equal order.kind_id, copy.kind_id
    assert_equal order.responsible_id, copy.responsible_id
    assert_equal order.department_id, copy.department_id
    assert_nil copy.billing_address_id
    assert_equal [], copy.order_team_members
    assert_equal [], copy.order_contacts
    assert_nil copy.contract

    assert_equal OrderStatus.defaults.pluck(:id).first, copy.status_id
    assert_nil copy.crm_key
  end

  test 'copies work item' do
    assert_nil copy.work_item.id
    assert_equal order.work_item.name, copy.work_item.name
    assert_equal order.work_item.shortname, copy.work_item.shortname
    assert_nil copy.work_item.description
    assert_equal order.work_item.parent_id, copy.work_item.parent_id
  end

  test 'copies has many associations' do
    order.order_team_members.create!(employee: employees(:pascal), comment: 'Coder')
    order.order_team_members.create!(employee: employees(:lucien), comment: 'PL')
    order.order_contacts.create!(contact: contacts(:puzzle_rava), comment: 'BL')
    order.comments.create!(text: 'foo', creator_id: 1, updater_id: 1)

    assert_equal 2, copy.order_team_members.size
    assert_equal employees(:lucien).id, copy.order_team_members.first.employee_id
    assert_equal 'PL', copy.order_team_members.first.comment

    assert_equal 1, copy.order_contacts.size
    assert_equal contacts(:puzzle_rava).id, copy.order_contacts.first.contact_id
    assert_equal 'BL', copy.order_contacts.first.comment

    assert_equal 0, copy.comments.size
  end

  test 'copies associations of order with multiple accounting posts' do
    order.create_contract!(number: 'hito1234', start_date: '2005-01-01', end_date: '2020-07-30')

    copier = Order::Copier.new(order)
    copy = copier.copy
    copier.copy_associations(copy)

    assert_equal 2, copy.work_item.children.size
    item = copy.work_item.children.first
    assert_nil item.id
    assert_equal 'App', item.name
    assert_equal 'APP', item.shortname
    assert_nil copy.work_item_id

    assert_nil copy.contract.id
    assert_equal order.contract.number, copy.contract.number
    assert_equal order.contract.start_date, copy.contract.start_date
    assert_equal order.contract.end_date, copy.contract.end_date

    source = accounting_posts(:hitobito_demo_app)
    post = item.accounting_post
    assert_nil post.id
    assert_equal source.portfolio_item_id, post.portfolio_item_id
    assert_equal source.offered_rate, post.offered_rate
    assert_equal source.billable, post.billable
    assert_equal source.description_required, post.description_required
    assert_equal false, post.closed
  end

  test 'copies associations of copies order with direct accounting post' do
    order = orders(:webauftritt)
    times = order.worktimes.count
    assert times > 0

    copier = Order::Copier.new(order)
    copy = copier.copy
    copy.work_item.name = 'Other name'
    copy.work_item.shortname = 'ONZ'
    copier.copy_associations(copy)
    copy.save!

    assert_equal 0, copy.work_item.children.size

    source = accounting_posts(:webauftritt)
    post = copy.work_item.accounting_post
    assert_not_equal post.id, source.id
    assert_equal source.portfolio_item_id, post.portfolio_item_id
    assert_equal source.offered_rate, post.offered_rate
    assert_equal source.billable, post.billable
    assert_equal source.description_required, post.description_required
    assert_equal false, post.closed

    copy = Order.find(copy.id)
    assert_equal 0, copy.worktimes.count
    assert_equal times, order.worktimes.count
  end

  test 'copy of closed order will be open' do
    order.update!(status: order_statuses(:abgeschlossen))
    assert_equal true, order.work_item.children.first.closed

    copier = Order::Copier.new(order)
    copy = copier.copy
    copy.work_item.name = 'Other name'
    copy.work_item.shortname = 'ONZ'
    copier.copy_associations(copy)
    copy.save!

    assert_equal OrderStatus.defaults.pluck(:id).first, copy.status_id
    assert_equal false, copy.work_item.children.first.reload.closed
  end

  test 'copy of closed accounting post will be open' do
    accounting_posts(:hitobito_demo_app).update!(closed: true)
    assert_equal true, order.work_item.children.first.closed

    copier = Order::Copier.new(order)
    copy = copier.copy
    copy.work_item.name = 'Other name'
    copy.work_item.shortname = 'ONZ'
    copier.copy_associations(copy)
    copy.save!

    assert_equal false, copy.work_item.children.first.reload.closed
  end

  def copy
    @copy ||= Order::Copier.new(order).copy
  end

  def order
    orders(:hitobito_demo)
  end
end
