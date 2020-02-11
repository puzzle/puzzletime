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
    # maybe we store the token in the session? it is valid for 5 minutes by
    # default. We could also ask keycloak with this method if the token is
    # still active.
    if access_token_valid?
      # Oh, and I almost forgot: this needs to be implemented...

      redirect_to params[:ref].presence || root_path # taken from previous version

    # with a refresh-token (valid for 30 minutes), we can get a new
    # access-token without prompting the user for a password
    elsif refresh_token_valid? # yep, also needs to be implemented

      refresh_access_token # you guessed it: this needs to be implemented

    else

      # should just work and do stupidly everything we need.
      # Essentially, we could replace this whole method with this redirect and
      # be done. Non-optimized, but done.
      redirect_to keycloak_authorization_uri # actually implemented (surprise)

      # this sends the UA to keycloak. If keycloak still knows the users, it
      # just redirects back to PTime (login#oauth) with a new code which allows
      # us to fetch a new access-token and ID-Token. This ID-Token tells us the
      # identity and allows us to log the user in.
      #
      # The only "gotcha": I only tested this in the console, not in actual
      # controller-code and certainly not with a production keycloak.
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
