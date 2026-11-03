# frozen_string_literal: true

#  Copyright (c) 2006-2026, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# Base of the Graphiti resources behind /api/v2. A resource names its `model` and its attributes (name and type);
# filtering, sorting, pagination, includes and writes follow from that.
#
# Authorization: override `base_scope` to restrict the rows a user can see (the default is every row); writes of any
# record in a request, including sideposted ones, are authorized against `Ability` here.
class ApplicationResource < Graphiti::Resource
  self.abstract_class = true
  adapter :active_record
  endpoint_namespace '/api/v2'

  before_save do |model|
    context.current_ability.authorize!(model.new_record? ? :create : :update, model)
  end

  before_destroy do |model|
    context.current_ability.authorize!(:destroy, model)
  end

  delegate :current_user, to: :context

  def management?
    current_user.try(:management?)
  end

  # The rows of `scope` the current user may see when they belong to an employee: management all of them, an
  # employee their own, everyone else (the api client) none.
  def own_or_all(scope)
    return scope.none unless current_user.is_a?(Employee)

    management? ? scope : scope.where(employee_id: current_user.id)
  end
end
