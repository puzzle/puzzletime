# -*- coding: utf-8 -*-
#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


class LoginController < ApplicationController
  skip_before_action :authenticate, except: [:logout]
  skip_authorization_check

  def index
    redirect_to action: 'login'
  end

  # Login procedure for user
  def login
    if request.post?
      if login_with(params[:user], params[:pwd])
        redirect_to params[:ref].presence || root_path
      else
        flash[:alert] = 'Ungültige Benutzerdaten'
      end
    end
  end

  def oauth
    fail 'horribly, but with a nice message' if session['oauth_nonce'] != params['state']

    keycloak_client.authorization_code = params['code']
    token = keycloak_client.access_token!
    id_token = token.raw_attributes['id_token']
    # should really be verified, see https://github.com/nov/json-jwt/wiki#decode--verify
    # public key is from keycloak, see http://<keycloak-server>/auth/realms/<realm-name>
    decoded_id = JSON::JWT.decode(id_token, :skip_verification)
    # contains:
    # "email_verified"     => true,
    # "name"               => "Tom Tester",
    # "preferred_username" => "nerd",
    # "given_name"         => "Tom",
    # "family_name"        => "Tester",
    # "email"              => "tom@example.org"
    @user ||= Employe.find(ldapname: decoded_id.fetch('preferred_username')) # upcase/downcase, maybe
  end

  # Logout procedure for user
  def logout
    reset_session
    flash[:notice] = 'Sie wurden ausgeloggt'
    redirect_to action: 'login'
  end
end
