# encoding: UTF-8

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
      date_from: Time.zone.today,
      date_to: Time.zone.today + 10.days }
  end
end
