# encoding: utf-8

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


# == Schema Information
#
# Table name: employment_roles_employments
#
#  id                       :integer          not null, primary key
#  employment_id            :integer          not null
#  employment_role_id       :integer          not null
#  employment_role_level_id :integer
#  percent                  :decimal(5, 2)    not null
#

class EmploymentRolesEmployment < ActiveRecord::Base
  belongs_to :employment
  belongs_to :employment_role
  belongs_to :employment_role_level, optional: true

  validates :percent, inclusion: 0..200
  validate :valid_level

  scope :list, -> { order('percent DESC') }

  def to_s
    level = if employment_role_level_id
              " #{employment_role_level}"
            else
              ''
            end

    "#{employment_role}#{level} #{percent.round}%"
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
