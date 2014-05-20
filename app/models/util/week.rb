# encoding: utf-8

class Week
  attr_reader :week, :year

  def self.from_string(week_string)
    week_string = week_string.gsub(/\s/, '')
    Week.new(week_string[0, 4].to_i, week_string[4, 5].to_i)
  end

  def self.from_integer(week_integer)
    Week.new(week_integer.to_s[0, 4].to_i, week_integer.to_s[4, 5].to_i)
  end

  def self.from_date(date)
    Week.new(date.cwyear, date.cweek)
  end

  def self.valid?(week_integer)
    week = from_integer(week_integer)
    Date.valid_commercial?(week.year, week.week, 1)
  end

  def initialize(year, week)
    @year = year
    @week = week
  end

  def to_integer
    @year * 100 + @week
  end

  def to_date
    Date.commercial(@year, @week, 1)
  end
end
