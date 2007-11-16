
class UserNotification < ActiveRecord::Base

  include Comparable
  extend Manageable
  
  # Validation helpers
  before_validation DateFormatter.new('date_from', 'date_to')
  validates_presence_of :date_from, :message => "Eine Startdatum muss angegeben werden"
  validates_presence_of :message, :message => "Eine Nachricht muss angegeben werden"
    
    
  def self.list_during(period=nil)
    period ||= Period.currentWeek
    custom = list(:conditions => ['date_from BETWEEN ? AND ? OR date_to BETWEEN ? AND ?', 
                                  period.startDate, period.endDate, 
                                  period.startDate, period.endDate],
                  :order => 'date_from')
    regular = Holiday.regular_holidays(period)  
    regular.collect! {|holiday| newHolidayNotification(holiday) }
    list = custom.concat(regular)
    list.sort!
  end  
    
  ##### Factory methods for Holidays #####

  def self.createHoliday(holiday)
    notification = newHolidayNotification(holiday)
    notification.save
  end
  
  def self.updateHoliday(holiday)
    previous = Holiday.find(holiday.id)
    destroyHoliday previous
    createHoliday holiday
  end
  
  def self.destroyHoliday(holiday)
    notification = findHoliday(holiday)
    notification.destroy if notification
  end
  
private

  def self.newHolidayNotification(holiday)
    new :date_from => holiday.holiday_date,
        :date_to => holiday.holiday_date,
        :message => holidayMessage(holiday)
  end

  def self.holidayMessage(holiday)
    holiday.holiday_date.strftime(LONG_DATE_FORMAT) + 
      " ist ein Feiertag (" + ("%01.2f" % holiday.musthours_day).to_s + 
      " Stunden Sollarbeitszeit)"
  end
  
  def self.findHoliday(holiday)
    date = holiday.holiday_date
    find(:first, :conditions => ['date_from = ? AND date_to = ? AND message = ?', 
                                 date, date, holidayMessage(holiay)])
  end   

public 

  def <=>(other)
    date_from <=> other.date_from
  end

  ##### interface methods for Manageable #####

  def label
    "die Nachricht '#{message}'"
  end

  def self.labels
    ['Die', 'Nachricht', 'Nachrichten']
  end

  def self.orderBy
    'date_from DESC, date_to DESC'
  end

  def validate
    errors.add(:date_to, "Enddatum muss nach Startdatum sein.") if date_from > date_to
  end
  
end