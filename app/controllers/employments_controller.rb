#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

class EmploymentsController < ManageController
  self.nesting = Employee

  self.permitted_attrs = [
    :percent, :start_date, :end_date,
    :vacation_days_per_year, :comment,
    employment_roles_employments_attributes: [
      :id,
      :employment_role_id,
      :percent,
      :employment_role_level_id,
      :_destroy
    ]
  ]

  before_render_form :load_employment_roles
  before_render_form :load_employment_role_levels
  before_render_form :prefill_from_newest_employment

  before_save :check_percent
  before_save :check_employment_role_uniqueness

  def list_entries
    super.includes(employment_roles_employments: [:employment_role,
                                                  :employment_role_level])
  end

  private

  def load_employment_roles
    @employment_roles = EmploymentRole.all
  end

  def load_employment_role_levels
    @employment_role_levels = EmploymentRoleLevel.all
  end

  def prefill_from_newest_employment
    return if entry.persisted? || params[:employment].present?

    newest = parent.employments.list.first
    if newest.present?
      entry.percent = newest.percent
      entry.employment_roles_employments = newest.employment_roles_employments.map(&:dup)
    end
  end

  def check_percent
    employment_roles_employments =
      params[:employment][:employment_roles_employments_attributes] || {}

    role_percent = employment_roles_employments
                   .values
                   .reject { |v| v[:_destroy] }
                   .collect { |v| v[:percent].to_i }
                   .sum

    if entry.percent.to_i != role_percent
      entry.errors.add(:percent, 'Funktionsanteile und Beschäftigungsgrad stimmen nicht überein.')
      throw :abort
    end
  end

  def check_employment_role_uniqueness
    employment_role_ids = entry.employment_roles_employments
                               .collect(&:employment_role_id)

    if employment_role_ids.length != employment_role_ids.uniq.length
      entry.errors.add(:employment_roles_employments, 'Funktionen können nicht doppelt erfasst werden.')
      throw :abort
    end
  end
end
