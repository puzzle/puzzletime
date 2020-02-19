#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


require 'test_helper'

# Test FormatHelper
class FormatHelperTest < ActionView::TestCase
  include UtilityHelper
  include I18nHelper
  include CrudTestHelper

  setup :reset_db, :setup_db, :create_test_data
  teardown :reset_db

  def format_size(obj)
    "#{f(obj.size)} items"
  end

  def format_string_size(obj)
    "#{f(obj.size)} chars"
  end

  test 'format number' do
    assert_nil format_number(nil)
    assert_equal '0.00', format_number(0.0001)
    assert_equal '0.50', format_number(0.5)
    assert_equal '8.33', format_number(8.33333)
    assert_equal '1&#39;234.56', format_number(1234.56)
  end

  test 'format hour' do
    assert_nil format_hour(nil)
    assert_equal '0.00 h', format_hour(0.0001)
    assert_equal '0.50 h', format_hour(0.5)
    assert_equal '8.33 h', format_hour(8.33333)
    assert_equal '1&#39;234.56 h', format_hour(1234.56)
  end

  test 'format day' do
    assert_equal 'Mo 16.6.', format_day(Date.new(2014, 6, 16))
    assert_equal 'Mi 18.6.', format_day(Date.new(2014, 6, 18))
    assert_equal 'Do 18.6.', format_day(Date.new(2099, 6, 18))
    assert_equal 'Donnerstag, 18.6.', format_day(Date.new(2099, 6, 18), true)
  end

  test 'format days' do
    assert_equal '5.00 Tage', format_days(5.0001)
    assert_equal '-1.23 Tage', format_days(-1.23)
  end

  test 'labeled text as block' do
    result = labeled('label') { 'value' }

    assert result.html_safe?
    assert_dom_equal '<dt>label</dt> ' \
                     "<dd class='value'>value</dd>",
                     result.squish
  end

  test 'labeled text empty' do
    result = labeled('label', '')

    assert result.html_safe?
    assert_dom_equal '<dt>label</dt> ' \
                     "<dd class='value'>#{EMPTY_STRING}</dd>",
                     result.squish
  end

  test 'labeled text as content' do
    result = labeled('label', 'value <unsafe>')

    assert result.html_safe?
    assert_dom_equal '<dt>label</dt> ' \
                     "<dd class='value'>value &lt;unsafe&gt;</dd>",
                     result.squish
  end

  test 'labeled attr' do
    result = labeled_attr('foo', :size)
    assert result.html_safe?
    assert_dom_equal '<dt>Size</dt> ' \
                     "<dd class='value'>3 chars</dd>",
                     result.squish
  end

  test 'format nil' do
    assert EMPTY_STRING.html_safe?
    assert_equal EMPTY_STRING, f(nil)
  end

  test 'format Strings' do
    assert_equal 'blah blah', f('blah blah')
    assert_equal '<injection>', f('<injection>')
    assert !f('<injection>').html_safe?
  end

  unless ENV['NON_LOCALIZED'] # localization dependent tests
    test 'format Floats' do
      assert_equal '1.00', f(1.0)
      assert_equal '1.20', f(1.2)
      assert_equal '3.14', f(3.14159)
    end

    test 'format Booleans' do
      assert_equal 'ja', f(true)
      assert_equal 'nein', f(false)
    end

    test 'format attr with fallthrough to f' do
      assert_equal '12.23', format_attr('12.23424', :to_f)
    end
  end

  test 'format attr with custom format_string_size method' do
    assert_equal '4 chars', format_attr('abcd', :size)
  end

  test 'format attr with custom format_size method' do
    assert_equal '2 items', format_attr([1, 2], :size)
  end

  test 'format integer column' do
    m = crud_test_models(:AAAAA)
    assert_equal '9', format_type(m, :children)

    m.children = 10_000
    assert_equal '10&#39;000', format_type(m, :children)
  end

  unless ENV['NON_LOCALIZED'] # localization dependent tests
    test 'format float column' do
      m = crud_test_models(:AAAAA)
      assert_equal '1.10', format_type(m, :rating)

      m.rating = 3.145001 # you never know with these floats..
      assert_equal '3.15', format_type(m, :rating)
    end

    test 'format decimal column' do
      m = crud_test_models(:AAAAA)
      assert_equal '10&#39;000&#39;000.1111', format_type(m, :income)
    end

    test 'format date column' do
      m = crud_test_models(:AAAAA)
      assert_equal 'Sa, 01.01.1910', format_type(m, :birthdate)
    end

    test 'format datetime column' do
      m = crud_test_models(:AAAAA)
      assert_equal '01.01.2010 11:21', format_type(m, :last_seen)
    end
  end

  test 'format time column' do
    m = crud_test_models(:AAAAA)
    assert_equal '01:01', format_type(m, :gets_up_at)
  end

  test 'format text column' do
    m = crud_test_models(:AAAAA)
    assert_equal "<p>AAAAA BBBBB CCCCC\n<br />AAAAA BBBBB CCCCC\n</p>",
                 format_type(m, :remarks)
    assert format_type(m, :remarks).html_safe?
  end

  test 'format boolean false column' do
    m = crud_test_models(:AAAAA)
    m.human = false
    assert_equal 'nein', format_type(m, :human)
  end

  test 'format boolean true column' do
    m = crud_test_models(:AAAAA)
    m.human = true
    assert_equal 'ja', format_type(m, :human)
  end

  test 'format belongs to column without content' do
    m = crud_test_models(:AAAAA)
    assert_equal t('global.associations.no_entry'),
                 format_attr(m, :companion)
  end

  test 'format belongs to column with content' do
    m = crud_test_models(:BBBBB)
    assert_equal 'AAAAA', format_attr(m, :companion)
  end

  test 'format has_many column with content' do
    m = crud_test_models(:CCCCC)
    assert_equal '<ul class="assoc_others"><li>AAAAA</li><li>BBBBB</li></ul>',
                 format_attr(m, :others)
  end

  test 'captionize' do
    assert_equal 'Camel Case', captionize(:camel_case)
    assert_equal 'All Upper Case', captionize('all upper case')
    assert_equal 'With Object', captionize('With object', Object.new)
    assert !captionize('bad <title>').html_safe?
  end
end
