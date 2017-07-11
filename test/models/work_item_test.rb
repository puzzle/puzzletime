# encoding: UTF-8
# == Schema Information
#
# Table name: work_items
#
#  id              :integer          not null, primary key
#  parent_id       :integer
#  name            :string           not null
#  shortname       :string(5)        not null
#  description     :text
#  path_ids        :integer          is an Array
#  path_shortnames :string
#  path_names      :string(2047)
#  leaf            :boolean          default(TRUE), not null
#  closed          :boolean          default(FALSE), not null
#

require 'test_helper'

class WorkItemTest < ActiveSupport::TestCase
  test 'new work_item get path names set' do
    p = Fabricate(:work_item,
                  parent_id: 1,
                  description: 'bla bla',
                  name: 'Foo',
                  shortname: 'FOO')

    assert_equal 'PITC-FOO', p.path_shortnames
    assert_equal "Puzzle\nFoo", p.path_names
    assert_equal 'bla bla', p.description
    assert_equal true, p.leaf
  end

  test 'new sub work_item get path names set' do
    p = Fabricate(:work_item,
                  parent_id: 1,
                  description: 'bla bla',
                  name: 'Foo',
                  shortname: 'FOO')
    c = Fabricate(:work_item,
                  parent_id: 1,
                  parent: p,
                  name: 'Bar',
                  shortname: 'BAR')

    assert_equal 'PITC-FOO-BAR', c.path_shortnames
    assert_equal "Puzzle\nFoo\nBar", c.path_names
    assert_nil c.description
  end

  test 'parent work_item leaf is reset when sub work_item is destroyed' do
    p = Fabricate(:work_item,
                  parent_id: 1)
    c = Fabricate(:work_item,
                  parent_id: 1,
                  parent: p)

    assert_equal true, c.leaf
    assert_equal false, p.leaf

    c.destroy

    assert_equal true, p.leaf
  end

  test 'sub work_item get path names set when parent name is changed' do
    p = Fabricate(:work_item,
                  parent_id: 1,
                  description: 'bla bla',
                  name: 'Foo',
                  shortname: 'FOO')
    c = Fabricate(:work_item,
                  parent_id: 1,
                  parent: p,
                  name: 'Bar',
                  shortname: 'BAR')

    p.reload
    p.update!(name: 'Fuu', description: 'bala bala')
    c.reload

    assert_equal 'PITC-FOO-BAR', c.path_shortnames
    assert_equal "Puzzle\nFuu\nBar", c.path_names
    assert_equal 'bala bala', p.description
  end

  test 'sub work_items get path names set when parent shortname is changed' do
    p = Fabricate(:work_item,
                  parent_id: 1,
                  name: 'Foo',
                  shortname: 'FOO')
    c1 = Fabricate(:work_item,
                   parent_id: 1,
                   parent: p,
                   description: 'yada',
                   name: 'Bar',
                   shortname: 'BAR')
    c2 = Fabricate(:work_item,
                   parent_id: 1,
                   parent: c1,
                   name: 'Baz',
                   shortname: 'BAZ')

    p.reload
    p.update_attributes!(shortname: 'FUU', description: 'bla')
    c1.reload
    c2.reload

    assert_equal 'PITC-FUU-BAR', c1.path_shortnames
    assert_equal "Puzzle\nFoo\nBar", c1.path_names
    assert_equal 'yada', c1.description
    assert_equal 'PITC-FUU-BAR-BAZ', c2.path_shortnames
    assert_equal "Puzzle\nFoo\nBar\nBaz", c2.path_names
    assert_nil c2.description
  end

  test 'sub work_item is not touched when parent names are not changed' do
    p = Fabricate(:work_item,
                  parent_id: 1,
                  name: 'Foo',
                  shortname: 'FOO')
    c = Fabricate(:work_item,
                  parent_id: 1,
                  parent: p,
                  name: 'Bar',
                  shortname: 'BAR')

    p.reload

    WorkItem.any_instance.expects(:store_path_names).never
    p.update_attributes!(description: 'foo')
  end

  test 'destroys dependent plannings when destroyed' do
    planning = plannings(:hitobito_demo_app_planning1)
    planning.work_item.destroy
    refute Planning.exists?(planning.id)
  end

  test '.with_worktimes_in_period includes only those work_items with billable worktimes in given period' do
    order = Fabricate(:order)
    work_items = Fabricate.times(4, :work_item, parent: order.work_item)
    work_items.each {|w| Fabricate(:accounting_post, work_item: w) }

    from, to = Date.parse('09.12.2006'), Date.parse('12.12.2006')

    (from..to).each_with_index do |date, index|
      Fabricate(:ordertime,
                work_date: date,
                work_item: work_items[index],
                employee: employees(:pascal)
      )
    end

    result = WorkItem.with_worktimes_in_period(order, from, to)
    assert 2, result.size
    assert_includes result, work_items.second
    assert_includes result, work_items.third
  end
end
