# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class Holiday < ActiveRecord::Base

   REGULARHOLIDAYS = [[1,1],[2,1],[25,12],[26,12],[1,8]]
   
  # Collection of functions to check if date is holiday or not       
  def self.musttime(date)
    if Holiday.isWeekend(date)
      return 0
    elsif Holiday.isRegularHoliday(date)
      return 0
    else 
      @@irregularHolidays.each{|holiday|
        if holiday.holiday_date = date
          return holiday.musthours_day
        end
      }
      return Masterdata.instance.musthours_day
    end
  end

  # Checks if date is a regular holiday
  def self.isRegularHoliday(date)
    REGULARHOLIDAYS.each{|day|
      if date.day == day[0] && date.month == day[1]
        return true
      end
    }
    return false
  end
  
  # 0 is Sunday, 6 is Saturday
  def self.isWeekend(date)
    return date.wday == 0 || date.wday == 6
  end
  
  def self.refresh
    @@irregularHolidays = Holiday.find(:all, :order => 'holiday_date')
  end
  
  # call refresh on class loading time
  self.refresh
end
