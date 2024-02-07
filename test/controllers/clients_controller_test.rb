# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'

class ClientsControllerTest < ActionController::TestCase
  include CrudControllerTestHelper

  setup :login

  not_existing :test_show,
               :test_show_json,
               :test_show_with_non_existing_id_raises_record_not_found

  def test_destroy
    @test_entry = Fabricate(:client)
    super
  end

  def test_destroy_json
    @test_entry = Fabricate(:client)
    super
  end

  def test_destroy_protected
    assert_no_difference("#{model_class.name}.count") do
      delete :destroy, params: test_params(id: test_entry.id)
    end
    assert_redirected_to_index
  end

  private

  # The entries as set by the controller.
  def entries
    @controller.send(:entries)
  end

  # Test object used in several tests.
  def test_entry
    @test_entry ||= clients(:swisstopo)
  end

  # Attribute hash used in several tests.
  def test_entry_attrs
    { work_item_attributes:
        { name: 'Initech',
          shortname: 'INIT' },
      e_bill_account_key: '41105678901234567',
      sector_id: sectors(:verwaltung).id }
  end
end
