# frozen_string_literal: true

#  Copyright (c) 2006-2026, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# For records without an Ability rule of their own (team members, contacts, additional CRM orders, work items):
# writing them is writing their order, so the Ability check of ApplicationResource is replaced by `:update` on
# `owner_of(model)`.
module AuthorizedThroughOrder
  extend ActiveSupport::Concern

  included do
    # ApplicationResource's generic hooks would deny everything that has no rule of its own.
    config[:callbacks][:save][:before].clear
    config[:callbacks][:destroy][:before].clear

    before_save { |model| authorize_owner(model) }
    before_destroy { |model| authorize_owner(model) }
  end

  private

  def authorize_owner(model)
    context.current_ability.authorize!(:update, owner_of(model))
  end

  def owner_of(model)
    model.order
  end
end
