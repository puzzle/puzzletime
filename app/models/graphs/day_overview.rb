class DayOverview
  
  def initialize
    @half_days = []
    @half_days_abstract = []
  end
  
  def add(half_day_label, abstract_amount = 0)
    if abstract_amount==0
      @half_days << HalfDay.new(half_day_label)
    else
      @half_days_abstract << HalfDayAbstract.new(half_day_label, abstract_amount)
    end
  end
  
  def label
    result = ''
    @half_days_abstract.each do |half_day|
      result << half_day.label
      result << '<br>' unless result =~ /<br>$/
    end
    @half_days.each do |half_day|
      result << half_day.label
      result << '<br>' unless result =~ /<br>$/
    end
    result
  end
  
  def style
    case @half_days.size
      when 0 then 'free'
      when 1 then 'half_planned'
      when 2 then 'full_planned'
    else 'over_planned'
    end
  end
  
  def percent
    perc = 0
    perc += @half_days.size * 10
    @half_days_abstract.each do |half_day|
      perc += half_day.abstract_amount
    end
    perc
  end
  
end


