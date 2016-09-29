require 'test_helper'

module Plannings
  class EmployeeListsControllerTest < ActionController::TestCase

    include CrudControllerTestHelper

    setup :login

    def test_create
      super
      assert_equal employees(:mark), entry.employee
    end

    private

    # Test object used in several tests.
    def test_entry
      employee_lists(:list_a)
    end

    # Attribute hash used in several tests.
    def test_entry_attrs
      { title: 'Happiness',
        employee_ids: [6, 7, 8] }
    end
  end
end