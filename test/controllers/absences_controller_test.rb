require 'test_helper'

class AbsencesControllerTest < ActionController::TestCase

  include CrudControllerTestHelper

  setup :login


  private

  # Test object used in several tests.
  def test_entry
    absences(:compensation)
  end

  # Attribute hash used in several tests.
  def test_entry_attrs
    { name: 'Geburt',
      payed: true,
      private: false }
  end
end
