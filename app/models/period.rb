include ActiveSupport::CoreExtensions::Time::Calculations::ClassMethods

class Period 

  attr_reader :startDate, :endDate, :label
  
  def self.currentWeek
    start = Time.now.at_beginning_of_week
    new(start, start.next_week, "This week: #{start.strftime('%W')}")
  end
  
  def self.currentMonth
    start = Time.now.at_beginning_of_month
    new(start, start.months_since(1), "This month: #{start.strftime('%m')}")    
  end
  
  def self.currentYear
    start = Time.now.at_beginning_of_year
    new(start, start.years_since(1), "This year: #{start.strftime('%y')}")
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
    @startDate.step(@endDate,1) {|date|
      yield date
    }
  end  
  
  def length
    ((@endDate - @startDate) + 1).to_i
  end
  
  def musttime
    sum = 0
    step {|date|
      sum += Holiday.musttime(date)
    }
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
