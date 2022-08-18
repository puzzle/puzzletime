#  Copyright (c) 2006-2022, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'

class Employees::SessionsControllerTest < ActionController::TestCase
  setup do
    @request.env['devise.mapping'] = Devise.mappings[:employee]
  end

  def test_only_omniauth_keycloakopenid_active
    Settings.auth.db.active = false
    Settings.auth.omniauth.keycloakopenid.active = true
    Settings.auth.omniauth.saml.active = false

    get :new

    assert_redirected_to employee_keycloakopenid_omniauth_authorize_path
  end

  def test_only_omniauth_saml_active
    Settings.auth.db.active = false
    Settings.auth.omniauth.keycloakopenid.active = false
    Settings.auth.omniauth.saml.active = true

    get :new

    assert_redirected_to employee_saml_omniauth_authorize_path
  end

  def test_only_local_auth_active
    Settings.auth.db.active = true
    Settings.auth.omniauth.keycloakopenid.active = false
    Settings.auth.omniauth.saml.active = false

    get :new

    assert_response :success
    assert_template :new
  end

  def test_multiple_omniauth_active
    Settings.auth.db.active = false
    Settings.auth.omniauth.keycloakopenid.active = true
    Settings.auth.omniauth.saml.active = true

    get :new

    assert_response :success
    assert_template :new
  end

  def test_local_auth_and_single_omniauth_active
    Settings.auth.db.active = true
    Settings.auth.omniauth.keycloakopenid.active = true
    Settings.auth.omniauth.saml.active = false

    get :new

    assert_response :success
    assert_template :new
  end
end
