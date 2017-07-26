# encoding: utf-8

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


# == Schema Information
#
# Table name: employments
#
#  id                     :integer          not null, primary key
#  employee_id            :integer
#  percent                :decimal(5, 2)    not null
#  start_date             :date             not null
#  end_date               :date
#  vacation_days_per_year :decimal(5, 2)
#  comment                :string
#

Fabricator(:employment) do
  percent    { 80 }
  start_date { 1.year.ago }
end
