# frozen_string_literal: true

#  Copyright (c) 2006-2026, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# Mirrors OrderCommentsController: everybody may comment, only the creator edits, nobody deletes. Listed per order
# (`/orders/:id/comments`, `include=comments`), so there is no index route.
class OrderCommentResource < ApplicationResource
  include AbilityScoped

  model OrderComment

  # Also listed per order, from `/orders/:id/comments`.
  self.validate_requests = false

  attribute :order_id, :integer, writable: :creating?
  attribute :text, :string
  attribute :creator_id, :integer, writable: false
  attribute :updater_id, :integer, writable: false
  attribute :created_at, :datetime, writable: false
  attribute :updated_at, :datetime, writable: false

  default_sort [{ updated_at: :desc }]

  # Writable guard: the order of a comment is fixed on creation.
  def creating?
    guard_model.new_record?
  end

  # Creator and updater are always the current user, which therefore has to be an employee.
  before_save do |model|
    raise CanCan::AccessDenied unless context.current_user.is_a?(Employee)

    model.updater = context.current_user
    model.creator ||= context.current_user
  end
end
