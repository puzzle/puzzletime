include ActiveSupport::CoreExtensions::Time::Calculations::ClassMethods

class Period 

  attr_reader :startDate, :endDate, :label
  
  def self.currentWeek
    self.weekFor(Date.today, "This week: #{Time.now.strftime('%W')}")
  end
  
  def self.currentMonth
    start = Date.today
    start -= start.day - 1
    new(start, start + days_in_month(start.month, start.year) - 1, "This month: #{Time.now.strftime('%m')}")    
   end
  
  def self.currentYear
    today = Date.today
    new(Date.civil(today.year, 1, 1), Date.civil(today.year, 12, 31), "This year: #{Time.now.strftime('%y')}")
  end
  
  def self.weekFor(date, label = nil)
    start = date
    start -= start.cwday - 1
    new(start, start + 6, label)    
  end
  
  def initialize(startDate, endDate, label = nil)
    @startDate = startDate
    @endDate = endDate
    @label = label != nil ? label : self.to_s
  end
    
  def step 
    @startDate.step(@endDate,1) do |date|
      yield date
    end
  end  
  
  def length
    ((@endDate - @startDate) + 1).to_i
  end
  
  def musttime
    sum = 0
    step do |date|
      sum += Holiday.musttime(date)
    end
    sum 
  end
  
  def include?(date)
    (@startDate..@endDate).include?(date)
  end
  
  def negative?
    @startDate > @endDate
  end
    
  def to_s
    formattedDate(@startDate) + ' - ' + formattedDate(@endDate)
  end  
  
private
  
  def formattedDate(date)
    "#{date.day}.#{date.month}.#{date.year}"
  end 

end
