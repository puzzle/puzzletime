#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


module Scopable
  extend ActiveSupport::Concern

  included do
    self.permitted_attrs = Array.wrap(self.permitted_attrs) + [:scope]
  end

  private

  def scope_entries_by(entries, *scopes)
    return entries unless scopes.map(&:to_s).include?(scope_param)

    entries.send(scope_param)
  end

  def scope_param
    params[:scope]
  end
end
