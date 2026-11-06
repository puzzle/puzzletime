# frozen_string_literal: true

#  Copyright (c) 2006-2025, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module Forms
  # Form object that books the same ordertime on consecutive days, up to the end of the week.
  # Only knows the dates; all other ordertime attributes stay in the request params.
  class MultiOrdertime
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :work_date, :date
    attribute :repetitions, :integer, default: 1

    attr_accessor :employee

    validates :work_date, presence: true
    validates :repetitions,
              presence: true,
              numericality: {
                only_integer: true,
                greater_than_or_equal_to: 1,
                less_than_or_equal_to: ->(form) { form.max_allowed_repetitions }
              },
              if: :work_date

    # The dates within the repetitions on which the employee is employed.
    def dates
      (work_date..end_date).select { |date| employee.employment_at(date) }
    end

    def max_allowed_repetitions
      return 1 unless work_date

      case work_date.wday
      when 0, 6 # Sunday, Saturday
        1
      else # Weekdays
        6 - work_date.wday
      end
    end

    private

    def end_date
      work_date + repetitions - 1
    end
  end
end
