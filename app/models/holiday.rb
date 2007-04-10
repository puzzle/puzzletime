# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class Holiday < ActiveRecord::Base
  
  extend Manageable

  after_save :refresh
  
  before_validation DateFormatter.new('holiday_date')
  
  validates_presence_of :holiday_date, :message => "Das Datum ist ung&uuml;ltig"  
  validates_presence_of :musthours_day, :message => "Die Muss Stunden m&uuml;ssen angegeben werden"
  
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
    date.wday == 0 || date.wday == 6
  end
      
  def self.refresh
    @@irregularHolidays = Holiday.find(:all, :order => 'holiday_date')
  end 
  
  def refresh
    Holiday.refresh
  end
  
  self.refresh
  
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
  
end
