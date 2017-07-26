# encoding: utf-8

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


# Used to generate static error pages with the application layout:
# RAILS_GROUPS=assets rails generate error_page {status}
class ErrorsController < ActionController::Base

  layout 'application'

  protect_from_forgery with: :exception

  def controller_module_name
    'root'
  end

end
