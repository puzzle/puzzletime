require 'test_helper'

class ClientsControllerTest < ActionController::TestCase

  #include CrudControllerTestHelper

  setup :login

  def test_index # :nodoc:
    get :index
    assert_response :success
    assert_template 'index'
    assert entries.present?
  end

  def test_index_json # :nodoc:
    get :index, format: 'json'
    assert_response :success
    assert entries.present?
    assert @response.body.starts_with?('[{'), @response.body
  end

  private

  # The entries as set by the controller.
  def entries
    @controller.send(:entries)
  end

  # Test object used in several tests.
  def test_entry
    departments(:swisstopo)
  end

  # Attribute hash used in several tests.
  def test_entry_attrs
    { name: 'Initech',
      shortname: 'INIT' }
  end
end
