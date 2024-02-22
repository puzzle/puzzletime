# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# == Schema Information
#
# Table name: worktimes
#
#  id              :integer          not null, primary key
#  absence_id      :integer
#  employee_id     :integer
#  report_type     :string(255)      not null
#  work_date       :date             not null
#  hours           :float
#  from_start_time :time
#  to_end_time     :time
#  description     :text
#  billable        :boolean          default(TRUE)
#  type            :string(255)
#  ticket          :string(255)
#  work_item_id    :integer
#  invoice_id      :integer
#

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
