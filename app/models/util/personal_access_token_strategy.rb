# frozen_string_literal: true

#  Copyright (c) 2006-2026, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

class PersonalAccessTokenStrategy < Devise::Strategies::Base

  def valid?
    request.headers['Authorization'].present?
  end

  def authenticate!
    auth_header = request.headers['Authorization']
    token_string = auth_header.to_s.gsub(/^Bearer /, '')
    pat = PersonalAccessToken.search_token(token_string)

    if pat
      pat.touch_last_used!
      Current.personal_access_token = pat
      success!(pat.employee)
    else
      fail!(:invalid_token)
    end
  end
end
