# frozen_string_literal: true

#  Copyright (c) 2006-2024, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'

class MarketOpportunitiesControllerTest < ActionDispatch::IntegrationTest
  include CrudControllerTestHelper

  setup :login

  not_existing :test_show,
               :test_show_json,
               :test_show_with_non_existing_id_raises_record_not_found

  private

  # Test object used in several tests.
  def test_entry
    market_opportunities(:one)
  end

  # Attribute hash used in several tests.
  def test_entry_attrs
    { name: 'Marktopportunität', active: true }
  end
end
