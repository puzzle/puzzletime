#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


class AddTargetScopeRatingDescriptions < ActiveRecord::Migration[5.1]
  def change
    OrderTarget::RATINGS.each do |rating|
      add_column :target_scopes, "rating_#{rating}_description".to_sym, :string
    end
  end
end
