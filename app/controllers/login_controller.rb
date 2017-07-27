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
