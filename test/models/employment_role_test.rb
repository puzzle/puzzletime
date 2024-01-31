#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# == Schema Information
#
# Table name: employment_roles
#
#  id                          :integer          not null, primary key
#  name                        :string           not null
#  billable                    :boolean          not null
#  level                       :boolean          not null
#  employment_role_category_id :integer
#

require 'test_helper'

class EmploymentRoleTest < ActiveSupport::TestCase
  test 'string representation matches name' do
    assert_equal 'Software Engineer', employment_roles(:software_engineer).to_s
  end
end
