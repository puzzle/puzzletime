# encoding: utf-8

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


require 'test_helper'

class OrderKindsControllerTest < ActionController::TestCase
  include CrudControllerTestHelper

  setup :login

  not_existing :test_show,
               :test_show_json,
               :test_show_with_non_existing_id_raises_record_not_found,
               :test_destroy_json

  def test_destroy # :nodoc:
    assert_no_difference('OrderKind.count') do
      delete :destroy, params: { id: test_entry.id }
    end
    assert_redirected_to_index
  end

  def test_destroy_unreferenced
    kind = Fabricate(:order_kind)
    assert_difference('OrderKind.count', -1) do
      delete :destroy, params: { id: kind.id }
    end
    assert_redirected_to_index
  end

  private

  # Test object used in several tests.
  def test_entry
    order_kinds(:projekt)
  end

  # Attribute hash used in several tests.
  def test_entry_attrs
    { name: 'Mega Projekt' }
  end
end
