# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

# Methods added to this helper will be available to all templates in the application.

module ApplicationHelper
  
  # round time function.
  def round(hour)
    (hour.to_f * 100).round / 100.0
  end
  
  # Generates <select>-statement with id.
  # Needed for javascript
  def worktime_hour(name)
    html = %(<select id=")
    html << "#{name}"
    html << %(" name=")
    html << "#{name}"
    html << %(">)
    0.upto(23) do |hour|
      html << %(<option value=")
      html << "#{hour}"
      html << %(">)
      html << "#{hour}"
      html << %(</option>)
    end
    html << %(</select>)
  end
 
  # Generates <select>-statement with id.
  # Needed for javascript
  def worktime_minute(name)
    html = %(<select id=")
    html << "#{name}"
    html << %(" name=")
    html << "#{name}"
    html << %(">)
    0.upto(59) do |minute|
      html << %(<option value=")
      html << "#{minute}"
      html << %(">)
      html << "#{minute}"
      html << %(</option>)
    end
    html << %(</select>)   
  end

  # Change english datelayout to german one.
  def format_date(date)
    date.strftime("%d.%m.%Y")
  end     
end
