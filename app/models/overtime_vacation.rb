# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# == Schema Information
#
# Table name: overtime_vacations
#
#  id            :integer          not null, primary key
#  hours         :float            not null
#  employee_id   :integer          not null
#  transfer_date :date             not null
#

class OvertimeVacation < ApplicationRecord
  belongs_to :employee

  validates_by_schema
  validates :hours, inclusion: { in: 0.001...999_999, message: 'Die Stunden müssen positiv sein' }
  validates :transfer_date, timeliness: { date: true, allow_blank: true }

  scope :list, -> { order('transfer_date DESC') }

  def to_s
    "von #{hours} Stunden#{" am #{I18n.l(transfer_date)}" if transfer_date}"
  end
end
