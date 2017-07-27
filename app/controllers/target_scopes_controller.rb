#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


class TargetScopesController < ManageController
  self.permitted_attrs = [:name, :icon, :position,
                          :rating_green_description, :rating_orange_description, :rating_red_description]
end
