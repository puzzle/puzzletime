# encoding: utf-8

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


Kaminari.configure do |config|
  config.default_per_page = 20
  # config.max_per_page = nil
  config.window = 10
  # config.outer_window = 0
  # config.left = 0
  # config.right = 0
  # config.page_method_name = :page
  # config.param_name = :page
end


module Kaminari
  module Helpers
    class Tag
      # Monkey patch this method to always include the :page param
      def page_url_for(page)
        @template.url_for @params.merge(@param_name => page)
      end
    end
  end
end