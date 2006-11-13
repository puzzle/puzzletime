include ActiveSupport::CoreExtensions::Time::Calculations::ClassMethods

class Period 

  attr_reader :startDate, :endDate
  
  def self.currentWeek
    start = Date.today
    start -= start.cwday - 1
    new(start, start + 6)
  end
  
  def self.currentMonth
    start = Date.today
    start -= start.day - 1
    new(start, start + days_in_month(start.month, start.year) - 1)    
  end
  
  def self.currentYear
    today = Date.today
    new(Date.civil(today.year, 1, 1), Date.civil(today.year, 12, 31))
  end
  
  def initialize(startDate, endDate)
    @startDate = startDate
    @endDate = endDate
  end
  
  def to_s
    formattedDate(@startDate) + ' - ' + formattedDate(@endDate)
  end  
  
private
  
  def formattedDate(date)
    "#{date.day}.#{date.month}.#{date.year}"
  end 

end
