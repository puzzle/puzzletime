# frozen_string_literal: true

#  Copyright (c) 2006-2026, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# The work item of an order or client; read through them, written as their sidepost (no endpoint of its own).
class WorkItemResource < ApplicationResource
  include AuthorizedThroughOrder

  model WorkItem

  attribute :parent_id, :integer
  attribute :name, :string
  attribute :shortname, :string
  attribute :description, :string
  attribute :path_names, :string, writable: false
  attribute :path_shortnames, :string, writable: false

  # A work item can't move, and its parent must exist (the tree callbacks need it).
  def save(model, meta = nil)
    errors = model.errors
    if model.persisted? && model.parent_id_changed?
      errors.add(:parent_id, 'kann nicht geändert werden')
    elsif model.parent_id && !WorkItem.exists?(model.parent_id)
      errors.add(:parent_id, 'existiert nicht')
    end
    errors.any? ? model : super
  end

  private

  # New ones are checked like HTML (Ability lets everybody who may create orders or clients create work items);
  # existing ones belong to their order or client.
  def authorize_owner(model)
    owner = model.order || model.client
    return context.current_ability.authorize!(:update, owner) if owner

    context.current_ability.authorize!(model.new_record? ? :create : :update, model)
  end
end
