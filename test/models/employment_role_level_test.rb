# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# {{{
# == Schema Information
#
# Table name: employment_role_levels
#
#  id   :integer          not null, primary key
#  name :string           not null
#
# Indexes
#
#  index_employment_role_levels_on_name  (name) UNIQUE
#
# }}}

require 'test_helper'

class EmploymentRoleLevelTest < ActiveSupport::TestCase
  test 'string representation matches name' do
    assert_equal 'Senior', employment_role_levels(:senior).to_s
  end
end
