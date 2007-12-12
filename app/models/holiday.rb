# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class Holiday < ActiveRecord::Base
  
  include ActionView::Helpers::NumberHelper
  include Comparable
  extend Manageable

  after_save :refresh
  
  before_validation DateFormatter.new('holiday_date')
  
  validates_presence_of :holiday_date, :message => "Das Datum ist ung&uuml;ltig"  
  validates_presence_of :musthours_day, :message => "Die Muss Stunden m&uuml;ssen angegeben werden"
  validates_uniqueness_of :holiday_date, :message => "Pro Datum ist nur ein Feiertag erlaubt"
  
  
  def self.period_musttime(period)
    hours = workday_hours(period)
    holidays(period).each do |holiday|
      hours -= MUST_HOURS_PER_DAY - holiday.musthours_day
    end
    hours
  end
 
  # Collection of functions to check if date is holiday or not       
  def self.musttime(date)
    if Holiday.weekend?(date)
      return 0
    elsif Holiday.regularHoliday?(date)
      return 0
    else 
      @@irregularHolidays.each do |holiday|
        return holiday.musthours_day if holiday.holiday_date == date
      end
      return MUST_HOURS_PER_DAY
    end
  end

  # Checks if date is a regular holiday
  def self.regularHoliday?(date)
    REGULAR_HOLIDAYS.each do |day|
      return true if date.day == day[0] && date.month == day[1]
    end
    false
  end
  
  def self.irregularHoliday?(date)
    @@irregularHolidays.each do |holiday|
      return true if holiday.holiday_date == date
    end
    false  
  end
  
  # 0 is Sunday, 6 is Saturday
  def self.weekend?(date)
  	wday = date.wday
    wday == 0 || wday == 6
  end
  
  def self.holiday?(date)
    self.weekend?(date) || 
      self.regularHoliday?(date) || 
      self.irregularHoliday?(date)
  end
  
  # returns all holidays for the given period which fall on a weekday
  def self.holidays(period)
    holidays = @@irregularHolidays.select { |holiday|  period.include?(holiday.holiday_date) }
    irregulars = holidays.collect { |holiday| holiday.holiday_date }
    regulars = regular_holidays(period)
    regulars.each do |holiday| 
      holidays.push holiday if ! irregulars.include?(holiday.holiday_date)
    end
    holidays   
  end
  
  def self.regular_holidays(period)
    holidays = Array.new
    years = period.startDate.year..period.endDate.year
    years.each do |year|
      REGULAR_HOLIDAYS.each do |day|
         regular = Date.civil(year, day[1], day[0])
         if period.include?(regular) && ! weekend?(regular)
           holidays.push new(:holiday_date => regular, :musthours_day => 0)
         end
      end
    end
    holidays
  end
      

private

  def self.refresh
    @@irregularHolidays = Holiday.find(:all, :order => 'holiday_date')
    @@irregularHolidays = @@irregularHolidays.select do |holiday|
      ! weekend?(holiday.holiday_date)
    end
  end 
  
  def self.workday_hours(period)
    length = period.length
    weeks = length / 7
    hours = weeks * 5 * MUST_HOURS_PER_DAY
    if length % 7 > 0
      lastPeriod = Period.new(period.startDate + weeks * 7, period.endDate)
      lastPeriod.step do |day|
        hours += MUST_HOURS_PER_DAY if ! Holiday.weekend?(day)
      end
    end
    hours
  end
  
public
  
  def refresh
    Holiday.refresh
  end
  
  self.refresh
  
  ##### caching #####
  
  def holiday_date
  	# cache holiday date to prevent endless string_to_date conversion
  	@holiday_date ||= read_attribute(:holiday_date)
  end
  
  def holiday_date=(value)
  	write_attribute(:holiday_date, value)
	  @holiday_date = nil
  end
  
  ##### interface methods for Manageable #####
   
  def self.labels
    ['Der', 'Feiertag', 'Feiertage']
  end
  
  def self.orderBy
    'holiday_date DESC'
  end
  
  def label
    "den Feiertag am #{holiday_date.strftime(LONG_DATE_FORMAT)}"
  end
 
  def <=>(other)
    holiday_date <=> other.holiday_date
  end
  
end
