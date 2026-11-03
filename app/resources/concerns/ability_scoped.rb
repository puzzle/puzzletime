# frozen_string_literal: true

#  Copyright (c) 2006-2026, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# Rows are visible only when `Ability` lets the user read the model at all (all such models are class-level
# rules), also when reached through a relationship or include of another resource.
module AbilityScoped
  def base_scope
    context.current_ability.can?(:read, model) ? super : model.none
  end
end
