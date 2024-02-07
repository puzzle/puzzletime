# frozen_string_literal: true

#  Copyright (c) 2006-2022, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'

module Employees
  class SessionsControllerTest < ActionController::TestCase
    setup do
      @request.env['devise.mapping'] = Devise.mappings[:employee]
    end

    test 'helper auto_redirect? with only omniauth keycloadopenid active' do
      Settings.auth.db.active = false
      Settings.auth.omniauth.keycloakopenid.active = true
      Settings.auth.omniauth.saml.active = false

      assert_predicate @controller.view_context, :auto_redirect?
    end

    test 'helper auto_redirect? with only omniauth saml active' do
      Settings.auth.db.active = false
      Settings.auth.omniauth.keycloakopenid.active = false
      Settings.auth.omniauth.saml.active = true

      assert_predicate @controller.view_context, :auto_redirect?
    end

    test 'helper auto_redirect? with only local auth active' do
      Settings.auth.db.active = true
      Settings.auth.omniauth.keycloakopenid.active = false
      Settings.auth.omniauth.saml.active = false

      assert_not @controller.view_context.auto_redirect?
    end

    test 'helper auto_redirect? with multiple omniauth active' do
      Settings.auth.db.active = false
      Settings.auth.omniauth.keycloakopenid.active = true
      Settings.auth.omniauth.saml.active = true

      assert_not @controller.view_context.auto_redirect?
    end

    test 'helper auto_redirect? with local auth and single omniauth active' do
      Settings.auth.db.active = true
      Settings.auth.omniauth.keycloakopenid.active = true
      Settings.auth.omniauth.saml.active = false

      assert_not @controller.view_context.auto_redirect?
    end

    test 'helper auto_redirect? depending on param prevent_auto_login' do
      Settings.auth.db.active = false
      Settings.auth.omniauth.keycloakopenid.active = true
      Settings.auth.omniauth.saml.active = false

      get :new

      assert_predicate @controller.view_context, :auto_redirect?

      get :new, params: { prevent_auto_login: true }

      assert_not @controller.view_context.auto_redirect?
    end
  end
end
