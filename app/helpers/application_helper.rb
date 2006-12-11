# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

# Methods added to this helper will be available to all templates in the application.

module ApplicationHelper
  
  # round time function.
  def round(hour)
    "%.2f" % hour.to_f
  end
  
  # Change english datelayout to german one.
  def format_date(date)
    date.strftime("%a, %d.%m.%Y")
  end  
  
  # Generates <select>-statement with id.
  # Needed for javascript
  def worktime_hour(name, time)
    time = Time.now if time == nil  
    hour = time.hour
    html = %(<select id="#{name}")
    html << %(" name="#{name}">)
    0.upto(23) do |h|
      html << %(<option value="#{h}")
      if h == hour
        html << %( selected="selected")
      end 
      html << %( >#{h})
      html << %(</option>)
    end
    html << %(</select>)
  end
 
  # Generates <select>-statement with id.
  # Needed for javascript
  def worktime_minute(name, time)
    time = Time.now if time == nil  
    minute = time.min
    html = %(<select id="#{name}" )
    html << %(" name="#{name}">)
    0.upto(59) do |min|
      html << %(<option value="#{min}")
      if min == minute
        html << %( selected="selected")
      end  
      html << %( >#{min})
      html << %(</option>)
    end
    html << %(</select>)   
  end
   
end
