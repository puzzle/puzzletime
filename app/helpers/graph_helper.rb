module GraphHelper

  def weekday_header
    names = Date::DAYNAMES[1..6] + [Date::DAYNAMES[0]]
    names.collect! { |n| "<th>#{n}</th>" }
    names.join("\n")
  end

  def week_header
  	header = ''
    @graph.each_week do |day|
    	header += "<th>#{'%02d' % day.cweek}</th>\n"
    end
	header
  end
  
  def month_header
  	header = ''
  	current_month = @graph.period.startDate.month 
  	span = 0
  	@graph.each_week do |day|
  	  if day.month != current_month
    		header += append_month(current_month, span)
    		current_month = day.month
    		span = 0
      end
      span += 1
  	end
  	header += append_month(current_month, span)
  end
  
  def append_month(current_month, span)
  	header = "<th colspan=\"#{span}\">"
  	header += Date::MONTHNAMES[current_month] if span > 2
  	header += "</th>\n"  
  	header	
  end
  
  def weekbox_td(box)
  	if box
  	  "<td style=\"background-color: #{box.color};\"><a>#{box.height}<span>#{box.tooltip}</span></a></td>"
  	else
  	  "<td></td>"
	  end  	
  end
    
  def timebox_div(box)
    div = "<a>"
    div += image_tag('space.gif', 
                      'height' => "#{box.height}pt",
                      'border' => 0,
                      'style' => "background-color: #{box.color};") 
    div += "<span>#{box.tooltip}</span>" if not box.tooltip.strip.empty?               
    div += "</a>"  
    div
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
