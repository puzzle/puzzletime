# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'

# Test TableHelper
class TableHelperTest < ActionView::TestCase
  include UtilityHelper
  include FormatHelper
  include I18nHelper
  include CustomAssertions
  include CrudTestHelper
  include SortHelper

  setup :reset_db, :setup_db, :create_test_data, :empty_params
  teardown :reset_db

  attr_reader :entries

  def format_size(obj)
    "#{f(obj.size)} items"
  end

  def format_string_size(obj)
    "#{f(obj.size)} chars"
  end

  def empty_params
    def params
      {}
    end
  end

  def can?(_action, _resource)
    true
  end

  test 'empty table should render message' do
    result = plain_table_or_message([]) {}

    assert_predicate result, :html_safe?
    assert_match(%r{<div class=["']table["']>.*</div>}, result)
  end

  test 'non empty table should render table' do
    result = plain_table_or_message(%w[foo bar]) do |t|
      t.attrs :size, :upcase
    end

    assert_predicate result, :html_safe?
    assert_match(%r{^<div class="unindented"><table.*</table></div>$}, result)
  end

  test 'table with attrs' do
    expected = DryCrud::Table::Builder.table(
      %w[foo bar], self,
      class: 'table table-striped table-hover table-condensed'
    ) do |t|
      t.attrs :size, :upcase
    end
    actual = plain_table(%w[foo bar], :size, :upcase)

    assert_predicate actual, :html_safe?
    assert_equal expected, actual
  end

  test 'standard list table' do
    @entries = CrudTestModel.all

    table = with_test_routing do
      list_table
    end

    assert_count 7, REGEXP_ROWS, table
    assert_count 14, REGEXP_SORT_HEADERS, table
  end

  test 'custom list table with attributes' do
    @entries = CrudTestModel.all

    table = with_test_routing do
      list_table :name, :children, :companion_id
    end

    assert_count 7, REGEXP_ROWS, table
    assert_count 3, REGEXP_SORT_HEADERS, table
  end

  test 'custom list table with block' do
    @entries = CrudTestModel.all

    table = with_test_routing do
      list_table do |t|
        t.attrs :name, :children, :companion_id
        t.col('head') { |e| content_tag :span, e.income.to_s }
      end
    end

    assert_count 7, REGEXP_ROWS, table
    assert_count 4, REGEXP_HEADERS, table
    assert_count 0, REGEXP_SORT_HEADERS, table
    assert_count 6, %r{<span>.+?</span>}, table
  end

  test 'custom list table with attributes and block' do
    @entries = CrudTestModel.all

    table = with_test_routing do
      list_table :name, :children, :companion_id do |t|
        t.col('head') { |e| content_tag :span, e.income.to_s }
      end
    end

    assert_count 7, REGEXP_ROWS, table
    assert_count 3, REGEXP_SORT_HEADERS, table
    assert_count 4, REGEXP_HEADERS, table
    assert_count 6, %r{<span>.+?</span>}, table
  end

  test 'standard list table with ascending sort params' do
    def params
      { sort: 'children', sort_dir: 'asc' }
    end

    @entries = CrudTestModel.all

    table = with_test_routing do
      list_table
    end

    sort_header_asc = %r{<th><a .*?sort_dir=asc.*?>Children</a> &uarr;</th>}

    assert_count 7, REGEXP_ROWS, table
    assert_count 13, REGEXP_SORT_HEADERS, table
    assert_count 1, sort_header_asc, table
  end

  test 'standard list table with descending sort params' do
    def params
      { sort: 'children', sort_dir: 'asc' }
    end

    @entries = CrudTestModel.all

    table = with_test_routing do
      list_table
    end

    sort_header_asc = %r{<th><a .*?sort_dir=asc.*?>Children</a> &uarr;</th>}

    assert_count 7, REGEXP_ROWS, table
    assert_count 13, REGEXP_SORT_HEADERS, table
    assert_count 1, sort_header_asc, table
  end

  test 'list table with custom column sort params' do
    def params
      { sort: 'chatty', sort_dir: 'asc' }
    end

    @entries = CrudTestModel.all

    table = with_test_routing do
      list_table :name, :children, :chatty
    end

    sort_header_desc = %r{<th><a .*?sort_dir=asc.*?>Chatty</a> &uarr;</th>}

    assert_count 7, REGEXP_ROWS, table
    assert_count 2, REGEXP_SORT_HEADERS, table
    assert_count 1, sort_header_desc, table
  end

  test 'standard crud table' do
    @entries = CrudTestModel.all

    table = with_test_routing do
      crud_table
    end

    assert_count 7, REGEXP_ROWS, table
    assert_count 14, REGEXP_SORT_HEADERS, table
    assert_count 12, REGEXP_ACTION_CELL, table      # edit, delete links
  end

  test 'custom crud table with attributes' do
    @entries = CrudTestModel.all

    table = with_test_routing do
      crud_table :name, :children, :companion_id
    end

    assert_count 7, REGEXP_ROWS, table
    assert_count 3, REGEXP_SORT_HEADERS, table
    assert_count 12, REGEXP_ACTION_CELL, table      # edit, delete links
  end

  test 'custom crud table with block' do
    @entries = CrudTestModel.all

    table = with_test_routing do
      crud_table do |t|
        t.attrs :name, :children, :companion_id
        t.col('head') { |e| content_tag :span, e.income.to_s }
      end
    end

    assert_count 7, REGEXP_ROWS, table
    assert_count 6, REGEXP_HEADERS, table
    assert_count 6, %r{<span>.+?</span>}m, table
    assert_count 12, REGEXP_ACTION_CELL, table      # edit, delete links
  end

  test 'custom crud table with attributes and block' do
    @entries = CrudTestModel.all

    table = with_test_routing do
      crud_table :name, :children, :companion_id do |t|
        t.col('head') { |e| content_tag :span, e.income.to_s }
      end
    end

    assert_count 7, REGEXP_ROWS, table
    assert_count 3, REGEXP_SORT_HEADERS, table
    assert_count 6, REGEXP_HEADERS, table
    assert_count 6, %r{<span>.+?</span>}m, table
    assert_count 12, REGEXP_ACTION_CELL, table      # edit, delete links
  end

  def entry
    @entry ||= CrudTestModel.first
  end
end
