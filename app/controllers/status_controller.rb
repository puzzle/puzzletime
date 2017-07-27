#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


class StatusController < ApplicationController
  skip_before_action :authenticate
  skip_authorization_check

  def index
    result = ActiveRecord::Base.connected? ? 'OK' : 'ERROR: Can not connect to the database'
    render plain: result
  end
end
