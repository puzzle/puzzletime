# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# Used to generate static error pages with the application layout:
# rails generate error_page {status}
class ErrorsController < ApplicationController
  skip_authorization_check

  layout 'application'

  protect_from_forgery with: :exception

  def not_found
    render status: :not_found
  end

  def internal_server_error
    render status: :internal_server_error
  end

  def service_unavailable
    render status: :service_unavailable
  end

  def controller_module_name
    'root'
  end
end
