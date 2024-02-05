# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

class ReportType
  include Comparable

  attr_accessor :key, :name, :accuracy

  START_STOP = false

  def self.instances
    [
      ReportType::StartStopType::INSTANCE,
      ReportType::HoursDayType::INSTANCE,
      ReportType::HoursWeekType::INSTANCE,
      ReportType::HoursMonthType::INSTANCE
    ].freeze
  end

  def self.all_instances
    instances + [ReportType::AutoStartType::INSTANCE].freeze
  end

  def self.[](key)
    all_instances.find { |type| type.key == key.to_s }
  end

  def to_s
    key
  end

  def <=>(other)
    return unless other.is_a?(ReportType)

    accuracy <=> other.accuracy
  end

  def validate_worktime(worktime)
    worktime.errors.add(:hours, 'Stunden müssen positiv sein') if worktime.hours.to_f <= 0
  end

  def copy_times(source, target)
    target.hours = source.hours
  end

  def start_stop?
    self.class::START_STOP
  end

  def date_string(date)
    I18n.l(date, format: :long)
  end

  protected

  def initialize(key, name, accuracy)
    @key = key
    @name = name
    @accuracy = accuracy
  end

  def rounded_hours(worktime)
    hour = worktime.hours || 0.0
    minutes = ((hour - hour.floor) * 60).round.to_s.rjust(2, '0')
    hours = ActiveSupport::NumberHelper.number_to_delimited(hour.floor, delimiter: "'")
    "#{hours}:#{minutes}".html_safe
  end
end
