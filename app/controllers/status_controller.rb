#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

class StatusController < ApplicationController
  skip_before_action :authenticate
  skip_authorization_check

  # Is the web server OK?
  def health
    render json: { status: :ok }
  end

  # Are we ready to serve requests?
  def readiness
    ready, status, message = assess_readiness
    http_code = ready ? :ok : :internal_server_error

    render json: { status: status, message: message }, status: http_code
  end

  private

  def assess_readiness
    return [true, :ok, 'OK'] if can_query_database?

    [false, :service_unavailable, 'ERROR: Can not connect to the database']
  end

  def can_query_database?
    ActiveRecord::Base.connection.execute('SELECT 1')
    true
  rescue PG::Error, ActiveRecord::ActiveRecordError
    false
  end
end
