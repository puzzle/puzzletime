# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module Closable
  extend ActiveSupport::Concern

  included do
    before_update :remember_closed_change
    after_update :propagate_closed_change
    after_create :propagate_closed!
  end

  def propagate_closed!
    work_item.propagate_closed!(closed?)
  end

  def open?
    !closed
  end

  private

  def remember_closed_change
    return unless closed_changed?

    @closed_changed = true
  end

  def propagate_closed_change
    propagate_closed! if @closed_changed
    @closed_changed = nil
  end
end
