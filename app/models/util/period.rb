# encoding: utf-8

class Period
  attr_reader :start_date, :end_date

  # Caches the most used periods
  # Not sure yet if this really works in a stateless fcgi environment
  # At least for single requests...
  @@cache = Cache.new

  ####### constructors ########

  def self.current_day
    day_for(Time.zone.today)
  end

  def self.current_week
    week_for(Time.zone.today)
  end

  def self.current_month
    month_for(Time.zone.today)
  end

  def self.current_year
    year_for(Time.zone.today)
  end

  def self.day_for(date, label = nil)
    label ||= day_label date
    retrieve(date, date, label)
  end

  def self.week_for(date, label = nil)
    date = date.to_date if date.is_a? Time
    label ||= week_label date
    date -= (date.wday - 1) % 7
    retrieve(date, date + 6, label)
  end

  def self.month_for(date, label = nil)
    date = date.to_date if date.is_a? Time
    label ||= month_label date
    date -= date.day - 1
    retrieve(date, date + Time.days_in_month(date.month, date.year) - 1, label)
  end

  def self.quarter_for(date, label = nil)
    label ||= quarter_label date
    retrieve(Date.civil(date.year, date.month - 2, 1), date + Time.days_in_month(date.month, date.year) - 1, label)
  end

  def self.year_for(date, label = nil)
    label ||= year_label date
    retrieve(Date.civil(date.year, 1, 1), Date.civil(date.year, 12, 31), label)
  end

  def self.past_month(date = Time.zone.today, label = nil)
    date = date.to_date if date.is_a?(Time)
    retrieve(date - 28, date + 7, label)
  end

  def self.coming_month(date = Time.zone.today, label = nil)
    date = date.to_date if date.is_a?(Time)
    date -= (date.wday - 1) % 7
    retrieve(date, date + 28, label)
  end

  def self.next_three_months(date = Time.zone.today, label = nil)
    date = date.to_date if date.is_a?(Time)
    date -= (date.wday - 1) % 7
    retrieve(date, date + 3.months, label)
  end

  def self.parse(shortcut)
    range = shortcut[-1..-1]
    shift = shortcut[0..-2].to_i if range != '0'
    case range
    when 'd' then day_for Time.zone.now.advance(days: shift).to_date
    when 'w' then week_for Time.zone.now.advance(days: shift * 7).to_date
    when 'm' then month_for Time.zone.now.advance(months: shift).to_date
    when 'q' then quarter_for Date.civil(Time.zone.now.year, shift * 3, 1)
    when 'y' then year_for Time.zone.now.advance(years: shift).to_date
    end
  end

  def self.retrieve(start_date = Time.zone.today, end_date = Time.zone.today, label = nil)
    start_date = parse_date(start_date)
    end_date = parse_date(end_date)
    key = [start_date, end_date, label]
    @@cache.get(key) { Period.new(start_date, end_date, label) }
  end

  # Build a period, even with illegal arguments
  def self.with(start_date = Time.zone.today, end_date = Time.zone_today, label = nil)
    start_date = parse_date(start_date) rescue nil
    end_date = parse_date(end_date) rescue nil
    new(start_date, end_date, label)
  end

  def initialize(start_date = Time.zone.today, end_date = Time.zone.today, label = nil)
    @start_date = self.class.parse_date(start_date)
    @end_date = self.class.parse_date(end_date)
    @label = label
  end


  #########  public methods  #########

  def &(other_period)
    return self if self == other_period
    new_start_date = [start_date, other_period.start_date].compact.max
    new_end_date = [end_date, other_period.end_date].compact.min
    Period.retrieve(new_start_date, new_end_date)
  end

  def step
    @start_date.step(@end_date, 1) do |date|
      yield date
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
    @url_query ||= 'start_date=' + start_date.to_s + '&amp;end_date=' + end_date.to_s
  end

  def limited?
    @start_date && @end_date
  end

  def ==(other)
    other.is_a?(Period) && other.start_date == start_date && other.end_date == end_date
  end

  def hash
    37 * start_date.hash ^ 43 * end_date.hash
  end

  def to_s
    if limited?
      if @start_date == @end_date
        I18n.l(@start_date)
      else
        I18n.l(@start_date) + ' - ' + I18n.l(@end_date)
      end
    elsif @start_date
      I18n.l(@start_date) + ' - egal'
    elsif @end_date
      'egal - ' + I18n.l(@end_date)
    else
      'egal - egal'
    end
  end

  def set_label(label)
    @label = label
  end

  def extend_to_weeks
    Period.new(Period.week_for(start_date).start_date,
               Period.week_for(end_date).end_date,
               label)
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

  private

  def self.day_label(date)
    case date
    when Time.zone.today then 'Heute'
    when Date.yesterday then 'Gestern'
    when Time.new.advance(days: -2).to_date then 'Vorgestern'
    when Date.tomorrow then 'Morgen'
    when Time.new.advance(days: 2).to_date then 'Übermorgen'
    else I18n.l(date)
    end
  end

  def self.week_label(date)
    "KW #{'%02d' % date.to_date.cweek}"
  end

  def self.month_label(date)
    I18n.l(date, format: '%B')
  end

  def self.quarter_label(date)
    "#{date.month / 4 + 1}. Quartal"
  end

  def self.year_label(date)
    I18n.l(date, format: '%Y')
  end

  def self.parse_date(date)
    return nil unless date.present?

    if date.is_a? String
      begin
        date = Date.strptime(date, I18n.t('date.formats.default'))
      rescue
        date = Date.parse(date)
      end
    end
    date = date.to_date if date.is_a? Time
    date
  end
end
