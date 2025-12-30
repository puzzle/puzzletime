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

    def save
      return false unless valid?

      ordertimes = []
      period.step do |date|
        employment = employee.employment_at(date)
        ordertimes << build_ordertime(date) if employment
      end

      Ordertime.transaction { ordertimes.each(&:save!) }
      ordertimes
    rescue ActiveRecord::RecordInvalid
      false
    end

    private

    def build_ordertime(date)
      shared_attrs = attributes.slice('account_id', 'ticket', 'description', 'internal_description', 'billable')

      Ordertime.new(shared_attrs).tap do |ot|
        ot.work_date = date
        ot.employee  = employee

        if start_stop?
          ot.report_type     = ReportType::StartStopType::INSTANCE
          ot.from_start_time = from_start_time
          ot.to_end_time     = to_end_time
        else
          ot.report_type     = ReportType::HoursDayType::INSTANCE
          ot.hours           = hours
        end
      end
    end

  end
end

