#  Copyright (c) 2006-2020, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'

class EmployeeMasterDataHelperTest < ActionView::TestCase
  include EmployeeMasterDataHelper

  test '#format_year_of_service' do
    employment_date = Date.tomorrow - 4.years
    assert_equal format_year_of_service(employment_date), 3
  end
end
