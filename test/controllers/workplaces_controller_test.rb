#  Copyright (c) 2006-2022, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'

class WorkplacesControllerTest < ActionController::TestCase
  include CrudControllerTestHelper

  setup :login

  private

  # Test object used in several tests.
  def test_entry
    workplaces(:zurich)
  end

  # Attribute hash used in several tests.
  def test_entry_attrs
    { name: "Ouagadougou" }
  end
end
