# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'

class BillingReportsControllerTest < ActionController::TestCase
  setup :login

  test 'GET index csv exports csv file' do
    get :index, format: :csv

    assert_match(/Kunde,Status,Geleistet,Verrechenbar,Verrechnet,Verrechnung offen/, response.body)
  end
end
