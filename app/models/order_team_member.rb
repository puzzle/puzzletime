# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# {{{
# == Schema Information
#
# Table name: order_team_members
#
#  id          :bigint           not null, primary key
#  comment     :string
#  employee_id :integer          not null
#  order_id    :integer          not null
#
# Indexes
#
#  index_order_team_members_on_employee_id_and_order_id  (employee_id,order_id) UNIQUE
#
# }}}

class OrderTeamMember < ApplicationRecord
  belongs_to :employee
  belongs_to :order

  validates_by_schema

  scope :list, lambda {
    includes(:employee).references(:employee).order('employees.lastname, employees.firstname')
  }

  def to_s
    [employee, comment.presence].compact.join(': ')
  end
end
