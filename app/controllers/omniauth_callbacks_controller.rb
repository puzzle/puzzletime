class OmniauthCallbacksController < Devise::OmniauthCallbacksController
  include OmniauthCallbacksHelper

  def default
    omni = request.env['omniauth.auth']
    authentication = Authentication.find_by(provider: omni['provider'], uid: omni['uid'])
    if authentication
      sign_in_user(authentication)
    elsif current_user
      add_new_oauth(authentication, omni)
    else
      login_with_matching_data(omni)
    end
  end

  # TODO: Username wegspeichern
  alias keycloakopenid default
  alias saml default
end
