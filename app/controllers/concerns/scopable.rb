#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


module Scopable
  extend ActiveSupport::Concern

  included do
    if self.respond_to?(:permitted_attrs=)
      self.permitted_attrs = Array.wrap(self.permitted_attrs) + [:scope]
    end
  end

  private

  def scoped(entries, *scopes)
    return entries unless scopes.map(&:to_s).include?(scope_param)

    entries.send(scope_param)
  end

  def scope_param
    params[:scope]
  end
end
