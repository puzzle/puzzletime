#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'

class OrderStatusesControllerTest < ActionController::TestCase
  include CrudControllerTestHelper

  setup :login

  not_existing :test_show,
               :test_show_json,
               :test_show_with_non_existing_id_raises_record_not_found,
               :test_destroy_json

  def test_destroy # :nodoc:
    assert_no_difference('OrderStatus.count') do
      delete :destroy, params: test_params(id: test_entry.id)
    end
    assert_redirected_to_index
  end

  def test_destroy_unreferenced
    status = Fabricate(:order_status, position: 30)
    assert_difference('OrderStatus.count', -1) do
      delete :destroy, params: { id: status.id }
    end
    assert_redirected_to_index
  end

  private

  # Test object used in several tests.
  def test_entry
    order_statuses(:bearbeitung)
  end

  # Attribute hash used in several tests.
  def test_entry_attrs
    { name: 'Full Stop',
      position: 15,
      style: 'danger' }
  end
end
