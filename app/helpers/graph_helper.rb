module GraphHelper

  def weekday_header
    names = Date::DAYNAMES[1..6] + [Date::DAYNAMES[0]]
    names.collect! { |n| "<th>#{n}</th>" }
    names.join("\n")
  end

  def timebox_div(box)
    image_tag('space.gif', 
              'height' => "#{box.height}pt",
              #'alt' => box.tooltip,
              'title' => box.tooltip,
              'style' => "background-color: #{box.color};")
  end

  def timebox_div_old(box)
    "<div style=\"background-color: #{box.color}; " +
         "height: #{box.height}pt;\" " +
         "title=\"#{box.tooltip}\"></div>"  
  end

  def day_td(date) 
    "<td#{Holiday.holiday?(date) ? ' class="holiday"' : ''}>"
  end

end
