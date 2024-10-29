# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# {{{
# == Schema Information
#
# Table name: worktimes
#
#  id                :integer          not null, primary key
#  billable          :boolean          default(TRUE)
#  description       :text
#  from_start_time   :time
#  hours             :float
#  meal_compensation :boolean          default(FALSE), not null
#  report_type       :string(255)      not null
#  ticket            :string(255)
#  to_end_time       :time
#  type              :string(255)
#  work_date         :date             not null
#  absence_id        :integer
#  employee_id       :integer
#  invoice_id        :integer
#  work_item_id      :integer
#
# Indexes
#
#  index_worktimes_on_invoice_id  (invoice_id)
#  worktimes_absences             (absence_id,employee_id,work_date)
#  worktimes_employees            (employee_id,work_date)
#  worktimes_work_items           (work_item_id,employee_id,work_date)
#
# Foreign Keys
#
#  fk_times_absences   (absence_id => absences.id) ON DELETE => cascade
#  fk_times_employees  (employee_id => employees.id) ON DELETE => cascade
#
# }}}

class Absencetime < Worktime
  self.account_label = 'Absenz'

  validates_by_schema
  validates :absence, presence: true

  attr_accessor :duration # used for multiabsence and not persisted

  def account
    absence
  end

  def account_id
    absence_id
  end

  def account_id=(value)
    self.absence_id = value
  end

  def absence?
    true
  end

  def billable
    false
  end
end
