# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# {{{
# == Schema Information
#
# Table name: plannings
#
#  id           :integer          not null, primary key
#  date         :date             not null
#  definitive   :boolean          default(FALSE), not null
#  percent      :integer          not null
#  employee_id  :integer          not null
#  work_item_id :integer          not null
#
# Indexes
#
#  index_plannings_on_employee_id                            (employee_id)
#  index_plannings_on_employee_id_and_work_item_id_and_date  (employee_id,work_item_id,date) UNIQUE
#  index_plannings_on_work_item_id                           (work_item_id)
#
# }}}

Fabricator(:planning) do |_f|
  date      { Time.zone.now.at_beginning_of_week.to_date + rand(5) }
  percent   { rand(1..10) * 10 }
  employee  { Employee.find(Employee.pluck(:id).sample) }
  work_item { WorkItem.find(WorkItem.pluck(:id).sample) }
end
