# encoding: utf-8

class Period

  # TODO: use underscore
  attr_reader :start_date, :end_date, :label

  # Caches the most used periods
  # Not sure yet if this really works in a stateless fcgi environment
  # At least for single requests...
  @@cache = Cache.new

  ####### constructors ########

  def self.current_day
    day_for(Date.today)
  end

  def self.current_week
    week_for(Date.today)
  end

  def self.current_month
    month_for(Date.today)
  end

  def self.current_year
    year_for(Date.today)
  end

  def self.day_for(date, label = nil)
    label ||= day_label date
    retrieve(date, date, label)
  end

  def self.week_for(date, label = nil)
    date = date.to_date if date.kind_of? Time
    label ||= week_label date
    date -= (date.wday - 1) % 7
    retrieve(date, date + 6, label)
  end

  def self.month_for(date, label = nil)
    date = date.to_date if date.kind_of? Time
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

  def self.past_month(date = Date.today, label = nil)
    date = date.to_date if date.kind_of? Time
    retrieve(date - 28, date + 7, label)
  end

  def self.coming_month(date = Date.today, label = nil)
    date = date.to_date if date.kind_of? Time
    date -= (date.wday - 1) % 7
    retrieve(date, date + 28, label)
  end

  def self.parse(shortcut)
    range = shortcut[-1..-1]
    shift = shortcut[0..-2].to_i if range != '0'
    case range
      when 'd' then day_for Time.new.advance(days: shift).to_date
      when 'w' then week_for Time.new.advance(days: shift * 7).to_date
      when 'm' then month_for Time.new.advance(months: shift).to_date
      when 'q' then quarter_for Date.civil(Time.new.year, shift * 3, 1)
      when 'y' then year_for Time.new.advance(years: shift).to_date
      else nil
    end
  end

  def self.retrieve(start_date = Date.today, end_date = Date.today, label = nil)
    start_date = parse_date(start_date)
    end_date = parse_date(end_date)
    key = [start_date, end_date, label]
    @@cache.get(key) { Period.new(start_date, end_date, label) }
  end

  def initialize(start_date = Date.today, end_date = Date.today, label = nil)
    @start_date = self.class.parse_date(start_date)
    @end_date = self.class.parse_date(end_date)
    @label = label ? label : to_s
  end


  #########  public methods  #########

  def step
    @start_date.step(@end_date, 1) do |date|
      yield date
    end
  end

  def length
    ((@end_date - @start_date) + 1).to_i
  end

  def musttime
  	# cache musttime because computation is expensive
    @musttime ||= Holiday.period_musttime(self)
  end

  def include?(date)
    date.between?(@start_date, @end_date)
  end

  def negative?
    @start_date > @end_date
  end

  def url_query_s
  	 @url_query ||= 'start_date=' + start_date.to_s + '&amp;end_date=' + end_date.to_s
  end

  def to_s
    (length > 1) ? I18n.l(@start_date) + ' - ' + I18n.l(@end_date) : I18n.l(@start_date)
  end

  def set_label(label)
    @label = label
  end


  private

  def self.day_label(date)
    case date
      when Date.today then 'Heute'
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
    if date.kind_of? String
      begin
        date = Date.strptime(date, I18n.t('date.formats.default'))
      rescue
        date = Date.parse(date)
      end
    end
    date = date.to_date if date.kind_of? Time
    date
  end

end
