#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


# == Schema Information
#
# Table name: employment_role_categories
#
#  id   :integer          not null, primary key
#  name :string           not null
#

require 'test_helper'

class EmploymentRoleCategoryTest < ActiveSupport::TestCase
  test 'string representation matches name' do
    assert_equal employment_role_categories(:management).to_s, 'Management'
  end
end
