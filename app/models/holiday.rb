# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class Holiday < ActiveRecord::Base

   REGULARHOLIDAYS = [[1,1],[2,1],[25,12],[26,12],[1,8]]
   VACATION_ID = 3
   
  # Collection of functions to check if date is holiday or not       
  def self.musttime(date)
    if Holiday.isWeekend(date)
      return 0
    elsif Holiday.isRegularHoliday(date)
      return 0
    else 
      holiday = Holiday.find(:first, :conditions => ["holiday_date = ?", date])
      if holiday != nil
        holiday.musthours_day
      else
        Masterdata.instance.musthours_day
      end
    end
  end

  # Checks if date is a regular holiday
  def self.isRegularHoliday(date)
    REGULARHOLIDAYS.each{|day|
      if date.month == day[1] && date.day == day[0]
        return true
      end
    }
    return false
  end
  
  # 0 is Sunday, 6 is Saturday
  def self.isWeekend(date)
    return date.wday == 0 || date.wday == 6
  end
end
