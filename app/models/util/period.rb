include ActiveSupport::CoreExtensions::Time::Calculations::ClassMethods

class Period 

  attr_reader :startDate, :endDate, :label
  
  # Caches the most used periods
  @@cache = Cache.new
  
  ####### constructors ########
  
  def self.currentDay
    self.dayFor(Date.today)
  end
  
  def self.currentWeek
    self.weekFor(Date.today)
  end
  
  def self.currentMonth
    self.monthFor(Date.today)
  end
  
  def self.currentYear
    self.yearFor(Date.today)
  end
  
  def self.dayFor(date, label = nil)
    label ||= dayLabel date
    retrieve(date, date, label)
  end
  
  def self.weekFor(date, label = nil)
    date = date.to_date if date.kind_of? Time   
    label ||= weekLabel date
    date -= (date.wday - 1) % 7
    retrieve(date, date + 6, label)    
  end
  
  def self.monthFor(date, label = nil) 
    date = date.to_date if date.kind_of? Time   
    label ||= monthLabel date
    date -= date.day - 1
    retrieve(date, date + days_in_month(date.month, date.year) - 1, label)    
  end
  
  def self.yearFor(date, label = nil)
    label ||= yearLabel date
    retrieve(Date.civil(date.year, 1, 1), Date.civil(date.year, 12, 31), label)  
  end
  
  def self.comingMonth(date = Date.today, label = nil)
    date = date.to_date if date.kind_of? Time
    date -= (date.wday - 1) % 7
    retrieve(date, date + 28, label)
  end
  
  def self.parse(shortcut)
    range = shortcut[-1..-1]
    shift = shortcut[0..-2].to_i if range != '0'
    case range
      when 'd' then dayFor Time.new.advance(:days => shift).to_date
      when 'w' then weekFor Time.new.advance(:days => shift * 7).to_date
      when 'm' then monthFor Time.new.advance(:months => shift).to_date
      when 'y' then yearFor Time.new.advance(:years => shift).to_date
      else nil
    end
  end
  
  def self.retrieve(startDate = Date.today, endDate = Date.today, label = nil)
    @@cache.get([startDate, endDate, label]) { Period.new(startDate, endDate, label) }
  end
  
  def initialize(startDate = Date.today, endDate = Date.today, label = nil)    
    @startDate = parseDate(startDate)
    @endDate = parseDate(endDate)
    @label = label ? label : self.to_s
  end
    
    
  #########  public methods  #########  
    
  def step 
    @startDate.step(@endDate,1) do |date|
      yield date
    end
  end  
  
  def length
    ((@endDate - @startDate) + 1).to_i
  end
  
  def musttime
  	# cache musttime because computation is expensive
    @musttime ||= Holiday.period_musttime(self)
  end
  
  def include?(date)
    date.between?(@startDate, @endDate) 
  end
  
  def negative?
    @startDate > @endDate
  end
  
  def url_query_s
  	@url_query ||= 'start_date=' + startDate.to_s + '&amp;end_date=' + endDate.to_s  	
  end
    
  def to_s
    formattedDate(@startDate) + ' - ' + formattedDate(@endDate)
  end  
  
private

  def self.dayLabel(date)
    case date
      when Date.today then 'Heute'
      when Date.yesterday then 'Gestern'
      when Time.new.advance(:days => -2).to_date then 'Vorgestern'
      when Date.tomorrow then 'Morgen'
      when Time.new.advance(:days => 2).to_date then '&Uuml;bermorgen'
      else date.strftime(DATE_FORMAT)
    end
  end

  def self.weekLabel(date)
    "KW #{"%02d" % date.to_date.cweek}"
  end

  def self.monthLabel(date)
    "#{date.strftime('%B')}"
  end
  
  def self.yearLabel(date)
    "#{date.strftime('%Y')}"
  end

  def parseDate(date)
    if date.kind_of? String
      begin
        date = Date.strptime(date, DATE_FORMAT) 
      rescue
        date = Date.parse(date)
      end
    end  
    date = date.to_date if date.kind_of? Time
    date
  end
  
  def formattedDate(date)
    date.strftime(DATE_FORMAT)
  end 

end
