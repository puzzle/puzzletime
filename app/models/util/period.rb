include ActiveSupport::CoreExtensions::Time::Calculations::ClassMethods

class Period 

  attr_reader :startDate, :endDate, :label
  
  def self.currentWeek
    self.weekFor(Date.today, "KW #{Time.now.strftime('%W')}")
  end
  
  def self.currentMonth
    self.monthFor(Date.today, "#{Date.today.strftime('%B')}")
  end
  
  def self.currentYear
    self.yearFor(Date.today, "#{Date.today.strftime('%Y')}")
  end
  
  def self.dayFor(date, label = nil)
    new(date, date, label)
  end
  
  def self.weekFor(date, label = nil)
    date = date.to_date if date.kind_of? Time
    date -= (date.wday - 1) % 7
    new(date, date + 6, label)    
  end
  
  def self.monthFor(date, label = nil) 
    date = date.to_date if date.kind_of? Time   
    date -= date.day - 1
    new(date, date + days_in_month(date.month, date.year) - 1, label)    
  end
  
  def self.yearFor(date, label = nil)
    new(Date.civil(date.year, 1, 1), Date.civil(date.year, 12, 31), label)  
  end
  
  def self.comingMonth(date = Date.today, label = nil)
    date = date.to_date if date.kind_of? Time
    date -= (date.wday - 1) % 7
    new(date, date + 28, label)
  end
  
  def initialize(startDate = Date.today, endDate = Date.today, label = nil)    
    @startDate = parseDate(startDate)
    @endDate = parseDate(endDate)
    @label = label ? label : self.to_s
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

  def parseDate(date)
    date = Date.strptime(date, DATE_FORMAT) if date.kind_of? String
    date = date.to_date if date.kind_of? Time
    date
  end
  
  def formattedDate(date)
    date.strftime(DATE_FORMAT)
  end 

end
