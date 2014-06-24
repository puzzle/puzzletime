# encoding: UTF-8

require 'test_helper'

class ClientsControllerTest < ActionController::TestCase

  include CrudControllerTestHelper

  setup :login

  not_existing :test_show,
               :test_show_json,
               :test_show_with_non_existing_id_raises_record_not_found

  def test_destroy
    assert_raises(RuntimeError) do
      super
    end
  end

  def test_destroy_json
    assert_raises(RuntimeError) do
      super
    end
  end

  private

  # The entries as set by the controller.
  def entries
    @controller.send(:entries)
  end

  # Test object used in several tests.
  def test_entry
    clients(:swisstopo)
  end

  # Attribute hash used in several tests.
  def test_entry_attrs
    { name: 'Initech',
      shortname: 'INIT' }
  end
end
