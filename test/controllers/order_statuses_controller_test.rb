require 'test_helper'

class OrderStatusesControllerTest < ActionController::TestCase

  include CrudControllerTestHelper

  setup :login

  not_existing :test_show,
               :test_show_json,
               :test_show_with_non_existing_id_raises_record_not_found

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
