# frozen_string_literal: true

#  Copyright (c) 2006-2022, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

class Employees::SessionsController < Devise::SessionsController
  helper_method :auto_redirect?

  private

  def no_local_auth?
    !Settings.auth.db.active
  end

  def omniauth_providers_active
    Settings.auth&.omniauth&.map(&:second)&.map(&:active)
  end

  def single_omniauth_provider?
    omniauth_providers_active&.one?
  end

  def auto_login_allowed?
    return true unless prevent = params[:prevent_auto_login]

    !ActiveRecord::Type::Boolean.new.deserialize(prevent)
  end

  def auto_redirect?
    auto_login_allowed? && no_local_auth? && single_omniauth_provider?
  end
end
