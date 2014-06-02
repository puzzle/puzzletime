require 'test_helper'

class UserNotificationsControllerTest < ActionController::TestCase

  include CrudControllerTestHelper

  setup :login


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
