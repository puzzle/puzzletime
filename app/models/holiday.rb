# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class Holiday < ActiveRecord::Base
  
  include ActionView::Helpers::NumberHelper
  extend Manageable

  before_create :createUserNotification
  before_update :updateUserNotification
  before_destroy :destroyUserNotification
  after_save :refresh
  
  before_validation DateFormatter.new('holiday_date')
  
  validates_presence_of :holiday_date, :message => "Das Datum ist ung&uuml;ltig"  
  validates_presence_of :musthours_day, :message => "Die Muss Stunden m&uuml;ssen angegeben werden"
  validates_uniqueness_of :holiday_date, :message => "Pro Datum ist nur ein Feiertag erlaubt"
  
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
  
  def self.regular_holidays(period)
    holidays = Array.new
    years = period.startDate.year..period.endDate.year
    years.each do |year|
      REGULAR_HOLIDAYS.each do |day|
         regular = Date.civil(year, day[1], day[0])
         if regular.between?(period.startDate, period.endDate)
           holidays.push new(:holiday_date => regular, :musthours_day => 0)
         end
      end
    end
    holidays
  end
      
  def self.refresh
    @@irregularHolidays = Holiday.find(:all, :order => 'holiday_date')
  end 
  
  def refresh
    Holiday.refresh
  end
  
  self.refresh
  
  # add user notification for new holiday
  def createUserNotification
    UserNotification.createHoliday(self)
  end
  
  def updateUserNotification
    UserNotification.updateHoliday(self)
  end
  
  def destroyUserNotification
    UserNotification.destroyHoliday(self)
  end
  
  def holiday_date
  	# cache holiday date to prevent endless string_to_date conversion
  	@holiday_date ||= read_attribute(:holiday_date)
  end
  
  def holiday_date=(value)
  	write_attribute(:holiday_date, value)
	  @holiday_date = nil
  end
  
public
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
