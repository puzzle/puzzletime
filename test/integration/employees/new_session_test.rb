# frozen_string_literal: true

#  Copyright (c) 2006-2022, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'

module Employees
  class NewSessionTest < ActionDispatch::IntegrationTest
    def setup
      # We use the rack_test driver as this one does not evaluate javascript.
      # This is required as we want to test if the page contains the necessary class attribute and javascript snippet
      # to execute the auto login. For this the auto login redirect can't actually happen.
      Capybara.current_driver = :rack_test
    end

    def teardown
      # Let's restore the original driver.
      Capybara.use_default_driver
    end

    test 'login button has auto-login class if eligible' do
      Settings.auth.db.active = false
      Settings.auth.omniauth.keycloakopenid.active = true
      Settings.auth.omniauth.saml.active = false

      visit new_employee_session_path

      assert_selector 'a.auto-login', text: 'Mit Puzzle SSO anmelden'
    end

    test 'login button does not have auto-login class if uneligible' do
      Settings.auth.db.active = true
      Settings.auth.omniauth.keycloakopenid.active = true
      Settings.auth.omniauth.saml.active = false

      visit new_employee_session_path

      assert_selector 'a', text: 'Mit Puzzle SSO anmelden'
      assert_no_selector 'a.auto-login', text: 'Mit Puzzle SSO anmelden'
    end

    test 'page includes auto-login javascript if eligible' do
      Settings.auth.db.active = false
      Settings.auth.omniauth.keycloakopenid.active = true
      Settings.auth.omniauth.saml.active = false

      visit new_employee_session_path

      assert_includes page.text(:all), "$('.auto-login').click()"
    end

    test 'page excludes auto-login javascript if uneligible' do
      Settings.auth.db.active = true
      Settings.auth.omniauth.keycloakopenid.active = true
      Settings.auth.omniauth.saml.active = false

      visit new_employee_session_path

      assert page.text(:all).exclude? "$('.auto-login').click()"
    end
  end
end
