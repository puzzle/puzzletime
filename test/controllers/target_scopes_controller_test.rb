require 'test_helper'

class TargetScopesControllerTest < ActionController::TestCase
  include CrudControllerTestHelper

  setup :login

  not_existing :test_show,
               :test_show_json,
               :test_show_with_non_existing_id_raises_record_not_found

  private

  # Test object used in several tests.
  def test_entry
    target_scopes(:time)
  end

  # Attribute hash used in several tests.
  def test_entry_attrs
    { name: 'Happiness',
      position: 5,
      icon: 'user' }
  end
end
