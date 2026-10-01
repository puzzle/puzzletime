# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'

# Guards the global Crm.instance against a stale CRM leaking across tests.
class CrmTest < ActiveSupport::TestCase
  teardown do
    Settings.reload!
    Crm.instance = nil
  end

  test 'init clears a previously initialised instance when no crm is configured' do
    Settings.odoo.api_url = nil
    Settings.highrise.api_token = 'test'

    assert_instance_of Crm::Highrise, Crm.init

    Settings.highrise.api_token = nil

    assert_nil Crm.init
    assert_nil Crm.instance
  end
end
