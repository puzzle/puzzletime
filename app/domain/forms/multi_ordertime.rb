# frozen_string_literal: true

#  Copyright (c) 2006-2025, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module Forms

  class MultiOrdertime
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :account_id, :integer
    attribute :ticket, :string
    attribute :description, :string
    attribute :internal_description, :string
    attribute :work_date, :date
    attribute :repetitions, :integer, default: 1
    attribute :hours, :decimal
    attribute :billable, :boolean
    attribute :from_start_time, :string
    attribute :to_end_time, :string

    attr_accessor :employee

    def start_stop?
      from_start_time.present? && to_end_time.present?
    end

    def end_date
      work_date + repetitions - 1
    end

    def period
      Period.new(work_date, end_date)
    end

    def prepare_each
      return enum_for(:prepare_each) unless block_given?

      period.step do |date|
        employment = employee.employment_at(date)
        next unless employment

        yield build_params(date)
      end
    end

    private

    def build_params(date)
      p = attributes.except('repetitions')
      p['work_date'] = date

      ActionController::Parameters.new(ordertime: p)
    end
  end
end

