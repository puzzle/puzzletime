# frozen_string_literal: true

#  Copyright (c) 2006-2026, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module Api
  module V1
    class AccountingPostSerializer < ApiSerializer
      attributes :name,
                 :offered_hours,
                 :offered_rate,
                 :offered_total,
                 :remaining_hours,
                 :billable,
                 :description_required,
                 :closed,
                 :from_to_times_required,
                 :billing_reminder_active,
                 :meal_compensation

      annotate_attributes :name,
                          :offered_hours,
                          :offered_rate,
                          :offered_total,
                          :remaining_hours,
                          :billable,
                          :description_required,
                          :closed,
                          :from_to_times_required,
                          :billing_reminder_active,
                          :meal_compensation

      belongs_to :work_item
      belongs_to :portfolio_item
      belongs_to :order
      belongs_to :service
    end
  end
end
