# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# {{{
# == Schema Information
#
# Table name: employment_roles
#
#  id                          :integer          not null, primary key
#  billable                    :boolean          not null
#  level                       :boolean          not null
#  name                        :string           not null
#  employment_role_category_id :integer
#
# Indexes
#
#  index_employment_roles_on_name  (name) UNIQUE
#
# }}}

class EmploymentRole < ApplicationRecord
  belongs_to :employment_role_category, optional: true
  has_many :employment_roles_employments, dependent: :restrict_with_exception

  validates_by_schema
  validates :name, uniqueness: { case_sensitive: false }

  def to_s
    name
  end
end
