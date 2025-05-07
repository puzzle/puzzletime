# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# {{{
# == Schema Information
#
# Table name: employment_roles_employments
#
#  id                       :integer          not null, primary key
#  percent                  :decimal(5, 2)    not null
#  employment_id            :integer          not null
#  employment_role_id       :integer          not null
#  employment_role_level_id :integer
#
# Indexes
#
#  index_unique_employment_employment_role  (employment_id,employment_role_id) UNIQUE
#
# }}}

class EmploymentRolesEmployment < ApplicationRecord
  has_paper_trail(meta: { employee_id: ->(e) { e.employment.employee_id } }, skip: [:id])

  belongs_to :employment
  belongs_to :employment_role
  belongs_to :employment_role_level, optional: true

  validates :percent, inclusion: 0..200
  validate :valid_level

  def to_s
    level = if employment_role_level_id
              " #{employment_role_level}"
            else
              ''
            end

    "#{employment_role}#{level} #{format('%g', percent)}%"
  end

  private

  def valid_level
    if employment_role.level? && !employment_role_level_id
      errors.add(:employment_role_level_id,
                 "Die Funktion '#{employment_role.name}' erfordert eine Stufe.")
    elsif !employment_role.level? && employment_role_level_id
      errors.add(:employment_role_level_id,
                 "Die Funktion '#{employment_role.name}' hat keine Stufen.")
    end
  end
end
