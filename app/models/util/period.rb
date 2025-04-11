# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

class Period
  attr_reader :start_date, :end_date, :shortcut

  ####### constructors ########

  class << self
    def current_day
      day_for(Time.zone.today)
    end

    def current_week
      week_for(Time.zone.today)
    end

    def current_month
      month_for(Time.zone.today)
    end

    def current_year
      year_for(Time.zone.today)
    end

    def day_for(date, options = {})
      date = date.to_date if date.is_a? Time
      options[:label] ||= day_label(date)
      new(date, date, options[:label], options[:shortcut])
    end

    def week_for(date, options = {})
      date = date.to_date if date.is_a? Time
      options[:label] ||= week_label(date)
      new(date.beginning_of_week, date.end_of_week,
          options[:label],
          options[:shortcut])
    end

    def month_for(date, options = {})
      date = date.to_date if date.is_a? Time
      options[:label] ||= month_label(date)
      new(date.beginning_of_month, date.end_of_month,
          options[:label],
          options[:shortcut])
    end

    def quarter_for(date, options = {})
      date = date.to_date if date.is_a? Time
      options[:label] ||= quarter_label(date)
      new(date.beginning_of_quarter, date.end_of_quarter,
          options[:label],
          options[:shortcut])
    end

    def year_for(date, options = {})
      date = date.to_date if date.is_a? Time
      options[:label] ||= year_label(date)
      new(date.beginning_of_year, date.end_of_year,
          options[:label],
          options[:shortcut])
    end

    def past_month(date = Time.zone.today, options = {})
      date = date.to_date if date.is_a?(Time)
      new(date - 28, date + 7, options[:label], options[:shortcut])
    end

    def previous_month(date = Time.zone.today)
      date = date.to_date if date.is_a?(Time)
      new(date.beginning_of_month - 1.month, date.beginning_of_month - 1.day)
    end

    def coming_month(date = Time.zone.today, options = {})
      date = date.to_date if date.is_a?(Time)
      date -= (date.wday - 1) % 7
      new(date, date + 28, options[:label], options[:shortcut])
    end

    def next_n_months(n, date = Time.zone.today, options = {})
      date = date.to_date if date.is_a?(Time)
      date -= (date.wday - 1) % 7
      options[:label] ||= next_n_months_label(n)
      options[:shortcut] ||= "#{n}M"
      new(date, date + n.months, options[:label], options[:shortcut])
    end

    def business_year_for(date, options = {})
      options[:label] ||= business_year_label(date)
      options[:shortcut] = 'b'
      year = date.month < Settings.defaults.business_year_start_month ? date.year - 1 : date.year
      business_year_start = Date.civil(year, Settings.defaults.business_year_start_month, 1)
      new(business_year_start, (date + 3.months).end_of_month, options[:label], options[:shortcut])
    end

    def parse(shortcut)
      range, shift = parse_shortcut(shortcut)
      now = Time.zone.now
      case range
      when 'd' then day_for(now.advance(days: shift), shortcut:)
      when 'w' then week_for(now.advance(days: shift * 7), shortcut:)
      when 'm' then month_for(now.advance(months: shift), shortcut:)
      when 'M' then next_n_months(shift, now)
      when 'q' then quarter_for(now.advance(months: shift * 3), shortcut:)
      when 'Q' then parse_year_quarter(now.year, shift, shortcut)
      when 'y' then year_for(now.advance(years: shift), shortcut:)
      when 'b' then business_year_for(now.to_date)
      end
    end

    def parse_year_quarter(year, shift, shortcut)
      raise ArgumentError, 'Unsupported shift for quarter shortcut' if [1, 2, 3, 4].exclude?(shift)

      quarter_for(Date.civil(year, shift * 3, 1), shortcut:)
    end

    # Build a period, even with illegal arguments
    def with(start_date = Time.zone.today, end_date = Time.zone.today, label = nil)
      # rubocop:disable Style/RescueModifier
      start_date = parse_date(start_date) rescue nil
      end_date = parse_date(end_date) rescue nil
      # rubocop:enable Style/RescueModifier
      new(start_date, end_date, label)
    end

    def parse_date(date)
      return nil if date.blank?

      if date.is_a?(String)
        if date.match?(/\A\d{1,2}\.\d{1,2}\.\d{2}\z/)
          day, month, short_year = date.split('.').map(&:to_i)

          # Get current full year and its century
          current_year = Time.zone.today.year
          cutoff = (current_year + 5) % 100
          current_century = (current_year / 100) * 100

          full_year = if short_year <= cutoff
                        current_century + short_year
                      else
                        (current_century - 100) + short_year
                      end

          return Date.new(full_year, month, day)
        end

        begin
          date = Date.strptime(date, I18n.t('date.formats.default'))
        rescue ArgumentError
          begin
            date = Date.parse(date)
          rescue StandardError
            date = nil
          end
        end
      end

      date = date.to_date if date.is_a?(Time)
      date
    end

    private

    def day_label(date)
      case date
      when Time.zone.today then 'Heute'
      when Date.yesterday then 'Gestern'
      when Time.zone.now.advance(days: -2).to_date then 'Vorgestern'
      when Date.tomorrow then 'Morgen'
      when Time.zone.now.advance(days: 2).to_date then 'Übermorgen'
      else I18n.l(date)
      end
    end

    def week_label(date)
      "KW #{format('%02d', date.to_date.cweek)}"
    end

    def month_label(date)
      I18n.l(date, format: '%B')
    end

    def quarter_label(date)
      "#{(date.month / 4) + 1}. Quartal"
    end

    def year_label(date)
      I18n.l(date, format: '%Y')
    end

    def next_n_months_label(n)
      "Nächste #{n} Monate"
    end

    def parse_shortcut(shortcut)
      range = shortcut[-1..]
      shift = shortcut[0..-2].to_i if range != '0'
      [range, shift]
    end

    def business_year_label(_date)
      'Geschäftsjahr/Ausblick'
    end
  end

  def initialize(start_date = Time.zone.today, end_date = Time.zone.today, label = nil,
                 shortcut = nil)
    @start_date = self.class.parse_date(start_date)
    @end_date = self.class.parse_date(end_date)
    @label = label
    @shortcut = shortcut
  end

  #########  public methods  #########

  def vacation_factor_sum
    (start_date.year..end_date.year).sum do |year|
      if start_date.year == year && end_date.year == year
        vacation_factor(start_date..end_date)
      elsif start_date.year == year
        vacation_factor(start_date..start_date.end_of_year)
      elsif end_date.year == year
        vacation_factor(end_date.beginning_of_year..end_date)
      else
        1
      end
    end
  end

  def vacation_factor(range)
    range.count.to_f / range.first.all_year.count
  end

  def &(other)
    return self if self == other

    new_start_date = [start_date, other.start_date].compact.max
    new_end_date = [end_date, other.end_date].compact.min
    Period.new(new_start_date, new_end_date)
  end

  def step(size = 1, &)
    return @start_date.step(@end_date, size) unless block_given?

    @start_date.step(@end_date, size, &)
  end

  def step_months
    return if unlimited?

    @start_date.beginning_of_month.step(@end_date.beginning_of_month) do |date|
      yield date if date.day == 1
    end
  end

  def length
    ((@end_date - @start_date) + 1).to_i
  end

  def label
    @label ||= to_s
  end

  def musttime
    # cache musttime because computation is expensive
    @musttime ||= Holiday.period_musttime(self)
  end

  def include?(date)
    date.between?(@start_date, @end_date)
  end

  def negative?
    limited? && @start_date > @end_date
  end

  def url_query_s
    @url_query ||= "start_date=#{start_date}&end_date=#{end_date}"
  end

  def limited?
    @start_date && @end_date
  end

  def unlimited?
    !limited?
  end

  def ==(other)
    other.is_a?(Period) && other.start_date == start_date && other.end_date == end_date
  end

  def hash
    (37 * start_date.hash) ^ (43 * end_date.hash)
  end

  def to_s
    if limited?
      if @start_date == @end_date
        I18n.l(@start_date)
      else
        "#{I18n.l(@start_date)} - #{I18n.l(@end_date)}"
      end
    elsif @start_date
      "#{I18n.l(@start_date)} - egal"
    elsif @end_date
      "egal - #{I18n.l(@end_date)}"
    else
      'egal - egal'
    end
  end

  def extend_to_weeks
    Period.new(start_date.at_beginning_of_week, end_date.at_end_of_week, label, shortcut)
  end

  def extend_to_months
    Period.new(start_date.beginning_of_month, end_date.end_of_month, label, shortcut)
  end

  def where_condition(column)
    if start_date && end_date
      ["#{column} BETWEEN ? AND ?", start_date, end_date]
    elsif start_date
      ["#{column} >= ?", start_date]
    elsif end_date
      ["#{column} <= ?", end_date]
    end
  end
end
