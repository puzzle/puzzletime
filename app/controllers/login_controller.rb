# encoding: utf-8

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
        flash[:notice] = 'Ungültige Benutzerdaten'
      end
    end
  end

  # Logout procedure for user
  def logout
    reset_session
    flash[:notice] = 'Sie wurden ausgeloggt'
    redirect_to action: 'login'
  end
end
