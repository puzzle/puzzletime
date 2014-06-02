require 'test_helper'

class UserNotificationsControllerTest < ActionController::TestCase

  include CrudControllerTestHelper

  setup :login

  not_existing :test_show,
               :test_show_json,
               :test_show_with_non_existing_id_raises_record_not_found

  private

  # Test object used in several tests.
  def test_entry
    user_notifications(:hello)
  end

  # Attribute hash used in several tests.
  def test_entry_attrs
    { message: 'Foo',
      date_from: Date.today,
      date_to: Date.today + 10.days }
  end
end
