#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


require 'test_helper'

class ContactsControllerTest < ActionController::TestCase
  include CrudControllerTestHelper

  setup :login

  not_existing :test_show,
               :test_show_json,
               :test_show_with_non_existing_id_raises_record_not_found


  private

  # Test object used in several tests.
  def test_entry
    contacts(:swisstopo_1)
  end

  # Attribute hash used in several tests.
  def test_entry_attrs
    { lastname: 'Muller',
      firstname: 'Hans',
      function: 'Chef',
      email: 'mueller@example.com',
      phone: '031 111 22 33',
      mobile: '079 111 22 33',
      crm_key: '123' }
  end
end
