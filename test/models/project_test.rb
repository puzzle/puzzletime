# encoding: UTF-8

require 'test_helper'

class ProjectTest < ActiveSupport::TestCase

  test 'new project get path names set' do
    p = Fabricate(:project,
                  client: clients(:puzzle),
                  department: departments(:devone),
                  description: 'bla bla',
                  name: 'Foo',
                  shortname: 'FOO')

    assert_equal 'PITC-FOO', p.path_shortnames
    assert_equal "Puzzle\nFoo", p.path_names
    assert_equal 'bla bla', p.inherited_description
    assert_equal true, p.leaf
  end

  test 'new sub project get path names set' do
    p = Fabricate(:project,
                  client: clients(:puzzle),
                  department: departments(:devone),
                  description: 'bla bla',
                  name: 'Foo',
                  shortname: 'FOO')
    c = Fabricate(:project,
                  client: clients(:puzzle),
                  department: departments(:devone),
                  parent: p,
                  name: 'Bar',
                  shortname: 'BAR')

    assert_equal 'PITC-FOO-BAR', c.path_shortnames
    assert_equal "Puzzle\nFoo\nBar", c.path_names
    assert_equal 'bla bla', c.inherited_description
  end

  test 'parent project leaf is reset when sub project is destroyed' do
    p = Fabricate(:project,
                  client: clients(:puzzle),
                  department: departments(:devone))
    c = Fabricate(:project,
                  client: clients(:puzzle),
                  department: departments(:devone),
                  parent: p)

    assert_equal true, c.leaf
    assert_equal false, p.leaf

    c.destroy

    assert_equal true, p.leaf
  end

  test 'sub project get path names set when parent name is changed' do
    p = Fabricate(:project,
                  client: clients(:puzzle),
                  department: departments(:devone),
                  description: 'bla bla',
                  name: 'Foo',
                  shortname: 'FOO')
    c = Fabricate(:project,
                  client: clients(:puzzle),
                  department: departments(:devone),
                  parent: p,
                  name: 'Bar',
                  shortname: 'BAR')

    p.reload
    p.update_attributes!(name: 'Fuu', description: 'bala bala')
    c.reload

    assert_equal 'PITC-FOO-BAR', c.path_shortnames
    assert_equal "Puzzle\nFuu\nBar", c.path_names
    assert_equal 'bala bala', p.inherited_description
  end

  test 'sub projects get path names set when parent shortname is changed' do
    p = Fabricate(:project,
                  client: clients(:puzzle),
                  department: departments(:devone),
                  name: 'Foo',
                  shortname: 'FOO')
    c1 = Fabricate(:project,
                  client: clients(:puzzle),
                  department: departments(:devone),
                  parent: p,
                  description: 'yada',
                  name: 'Bar',
                  shortname: 'BAR')
    c2 = Fabricate(:project,
                  client: clients(:puzzle),
                  department: departments(:devone),
                  parent: c1,
                  name: 'Baz',
                  shortname: 'BAZ')

    p.reload
    p.update_attributes!(shortname: 'FUU', description: 'bla')
    c1.reload
    c2.reload

    assert_equal 'PITC-FUU-BAR', c1.path_shortnames
    assert_equal "Puzzle\nFoo\nBar", c1.path_names
    assert_equal 'yada', c1.inherited_description
    assert_equal 'PITC-FUU-BAR-BAZ', c2.path_shortnames
    assert_equal "Puzzle\nFoo\nBar\nBaz", c2.path_names
    assert_equal 'yada', c2.inherited_description
  end

  test 'project and sub project get path names set when client shortname is changed' do
    p = Fabricate(:project,
                  client: clients(:puzzle),
                  department: departments(:devone),
                  name: 'Foo',
                  shortname: 'FOO')
    c = Fabricate(:project,
                  client: clients(:puzzle),
                  department: departments(:devone),
                  parent: p,
                  name: 'Bar',
                  shortname: 'BAR')

    clients(:puzzle).update_attributes!(shortname: 'PUZZ', name: 'Puzzle ITC')
    p.reload
    c.reload

    assert_equal 'PUZZ-FOO', p.path_shortnames
    assert_equal 'PUZZ-FOO-BAR', c.path_shortnames
    assert_equal "Puzzle ITC\nFoo\nBar", c.path_names
  end

  test 'sub project is not touched when parent names are not changed' do
    p = Fabricate(:project,
                  client: clients(:puzzle),
                  department: departments(:devone),
                  name: 'Foo',
                  shortname: 'FOO')
    c = Fabricate(:project,
                  client: clients(:puzzle),
                  department: departments(:devone),
                  parent: p,
                  name: 'Bar',
                  shortname: 'BAR')

    p.reload

    Project.any_instance.expects(:store_path_names).never
    p.update_attributes!(offered_hours: 40)
  end
end
