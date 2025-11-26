# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'

class InvoiceReportsControllerTest < ActionController::TestCase
  setup :login

  test 'GET index csv exports csv file' do
    get :index, params: { responsible_id: employees(:lucien).id }, format: :csv

    assert_match(%r{Referenz,Kunde / Auftrag,Leistungsperiode,Rechnungsdatum,Fälligkeitsdatum,Status,Rechnungsbetrag,Total Stunden,OE,Verantwortlich,Manuell}, response.body)
  end
end
