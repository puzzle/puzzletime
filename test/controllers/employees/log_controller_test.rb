#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


require 'test_helper'

class Employees::LogControllerTest < ActionController::TestCase

  setup :login

  test 'denies access for non-management users' do
    employees(:mark).update_attributes(management: false)
    assert_raise CanCan::AccessDenied do
      get :index, params: { id: pedro.id }
    end
  end

  test 'renders empty log' do
    get :index, params: { id: pedro.id }
    assert_match(/Keine Änderungen/, response.body)
  end

  test 'renders log in correct order' do
    pedro.update_attributes(street: 'Belpstrasse 37', postal_code: '3007', city: 'Bern')
    pedro.update_attributes(phone_private: '+41791234567')
    pedro.update_attributes(committed_worktimes_at: Time.zone.now) # should not appear in log
    get :index, params: { id: pedro.id }
    assert_select('.log tbody tr', count: 2)
    assert_select('.log tbody tr:nth-child(1) td:nth-child(2)', text: 'Telefon Privat wurde auf «+41791234567» gesetzt.')
    assert_select('.log tbody tr:nth-child(2) td:nth-child(2)', text: 'Strasse wurde auf «Belpstrasse 37» gesetzt.' \
                                                                      'PLZ wurde auf «3007» gesetzt.' \
                                                                      'Ort wurde auf «Bern» gesetzt.')
  end

  private

  def pedro
    employees(:various_pedro)
  end

end
