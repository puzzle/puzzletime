# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# A Module that provides the funcionality for a model object to be evaluated.
#
# A class mixin Evaluatable has to provide a has_many relation for worktimes.
# See Evaluation for further details.
module Evaluatable
  include Comparable
  include Conditioner

  # The displayed label of this object.
  def label
    to_s
  end

  # A more complete label, defaults to the normal label method.
  def label_verbose
    label
  end

  # A tooltip to display in a list
  def tooltip
    nil
  end

  def <=>(other)
    return unless other.is_a?(Evaluatable)
    return super if is_a? Class

    label_verbose <=> other.label_verbose
  end
end
