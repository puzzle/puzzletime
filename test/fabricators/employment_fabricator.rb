# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# {{{
# == Schema Information
#
# Table name: employments
#
#  id                     :integer          not null, primary key
#  comment                :string
#  end_date               :date
#  percent                :decimal(5, 2)    not null
#  start_date             :date             not null
#  vacation_days_per_year :decimal(5, 2)
#  employee_id            :integer
#
# Indexes
#
#  index_employments_on_employee_id  (employee_id)
#
# Foreign Keys
#
#  fk_employments_employees  (employee_id => employees.id) ON DELETE => cascade
#
# }}}

Fabricator(:employment) do
  employee
  percent    { 80 }
  start_date { 1.year.ago }
  employment_roles_employments(count: 1) do |attrs|
    Fabricate.build(:employment_roles_employment, percent: attrs[:percent])
  end
end
