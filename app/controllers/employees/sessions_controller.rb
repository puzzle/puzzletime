# frozen_string_literal: true

#  Copyright (c) 2006-2022, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

class Employees::SessionsController < Devise::SessionsController
  # GET /resource/sign_in
  def new
    return redirect_to auto_redirect_path if auto_redirect?

    super
  end

  private

  def local_auth?
    Settings.auth.db.active
  end

  def single_omniauth_provider?
    Settings.auth&.omniauth&.map(&:second)&.map(&:active)&.one?
  end

  def auto_redirect?
    !local_auth? && single_omniauth_provider?
  end

  def auto_redirect_path
    provider = Settings.auth&.omniauth.to_h.find { |_, options| options[:active] }&.first
    public_send("employee_#{provider}_omniauth_authorize_path")
  end
end
