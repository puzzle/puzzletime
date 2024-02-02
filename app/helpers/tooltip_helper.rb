# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module TooltipHelper
  def with_tooltip(tooltip_text, options = {}, &)
    tag = options.delete(:tag) || :span
    options = options.merge(title: tooltip_text, data: { toggle: :tooltip })
    content_tag(tag, options, &)
  end
end
