# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'

module Plannings
  class CompaniesControllerTest < ActionController::TestCase
    setup :login

    test 'GET #show renders values of all employed employees' do
      get :show

      assert_equal employees(:various_pedro, :next_year_pablo, :long_time_john),
                   assigns(:overview).boards.map(&:employee)
    end
  end
end
