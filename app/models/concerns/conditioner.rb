# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module Conditioner
  def append_conditions(existing, appends, cat = 'AND')
    if existing.nil?
      existing = ['']
    elsif existing.empty? # keep object reference
      existing.push ''
    else
      existing[0] = "( #{existing[0]} ) #{cat} "
    end
    existing[0] += appends[0]
    existing.concat appends[1..]
  end

  def clone_conditions(conditions)
    return conditions.clone if conditions

    []
  end

  # only use if conditions will be added later on!
  def clone_options(options = {})
    options = options.clone
    options[:conditions] = clone_conditions options[:conditions]
    options
  end
end
