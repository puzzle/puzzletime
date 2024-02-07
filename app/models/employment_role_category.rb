# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# == Schema Information
#
# Table name: employment_role_categories
#
#  id   :integer          not null, primary key
#  name :string           not null
#

class EmploymentRoleCategory < ApplicationRecord
  has_many :employment_roles, dependent: :restrict_with_exception

  validates_by_schema
  validates :name, uniqueness: { case_sensitive: false }

  def to_s
    name
  end
end
