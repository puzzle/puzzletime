# frozen_string_literal: true

#  Copyright (c) 2006-2026, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# Mirrors EmploymentsController: management sees and edits all employments, employees only list their own.
#
# The roles (EmploymentRolesEmployment) are written like the HTML form does, as Rails nested attributes in the
# write-only attribute `employment_roles_employments_attributes` (`id`, `employment_role_id`,
# `employment_role_level_id`, `percent`, `_destroy`) and read through the `employment_roles_employments`
# relationship (`include=`). Graphiti's sideposting cannot be used: it saves the employment before its roles, but
# `Employment` requires roles to be saved, and a role requires a saved employment.
class EmploymentResource < ApplicationResource
  model Employment

  ROLE_KEYS = %w[id employment_role_id employment_role_level_id percent _destroy].freeze

  self.default_sort = [{ start_date: :desc }]

  attribute :employee_id, :integer
  attribute :percent, :big_decimal
  attribute :start_date, :date
  attribute :end_date, :date
  attribute :vacation_days_per_year, :big_decimal
  attribute :comment, :string
  attribute :employment_roles_employments_attributes, :array,
            readable: false, filterable: false, sortable: false

  belongs_to :employee
  has_many :employment_roles_employments, link: false, writable: false

  def base_scope
    own_or_all(Employment.all)
  end

  before_attributes only: [:update] do |attributes|
    attributes.delete(:employee_id)
  end

  # Nothing but the role columns may reach the nested attributes (`employment_id` would move a role).
  before_attributes do |attributes|
    roles = attributes[:employment_roles_employments_attributes]
    attributes[:employment_roles_employments_attributes] = roles.grep(Hash).map { |role| role.stringify_keys.slice(*ROLE_KEYS) } if roles
  end

  # The checks of EmploymentsController (before_save callbacks) on the assigned employment, so roles marked for
  # destruction do not count; errors added here fail the request (422) and skip saving.
  def save(model, meta = nil)
    check_percent(model)
    check_role_uniqueness(model)
    check_previous_employment(model)
    model.errors.any? ? model : super
  end

  private

  def kept_roles(model)
    model.employment_roles_employments.reject(&:marked_for_destruction?)
  end

  def check_percent(model)
    return unless model.percent && model.percent != kept_roles(model).sum { |role| role.percent || 0 }

    model.errors.add(:percent, 'Funktionsanteile und Beschäftigungsgrad stimmen nicht überein.')
  end

  def check_role_uniqueness(model)
    role_ids = kept_roles(model).map(&:employment_role_id)
    return unless role_ids.length != role_ids.uniq.length

    model.errors.add(:employment_roles_employments, 'Funktionen können nicht doppelt erfasst werden.')
  end

  # Employment#update_previous_end_date closes the previous employment with `save!`, whose failure would be a 500.
  def check_previous_employment(model)
    return unless model.new_record? && model.start_date && model.employee_id

    previous = model.previous_employment
    return unless previous

    previous.end_date = model.start_date - 1
    previous.errors.full_messages.each { |message| model.errors.add(:previous_employment, message) } unless previous.valid?
  end
end
