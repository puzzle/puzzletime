class DayOverview
  
  def initialize
    @half_days = []
  end
  
  def add(half_day_label)
    @half_days << HalfDay.new(half_day_label)
  end
  
  def label
    result = ''
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
    @half_days.size * 10
  end
  
end


