module GraphHelper

  def extend_to_weeks(period)
    Period.new Period.weekFor(period.startDate).startDate,
               Period.weekFor(period.endDate).endDate,
               period.label
  end

  def each_day
    @period.startDate.step(@period.endDate) do |day|
      @current = get_period_week(day)
      yield day
    end
  end

  def each_week
    @period.startDate.step(@period.endDate, 7) do |week|
      @current = get_period_week(week)
      yield week
    end
  end

  def get_period_month(date)
    get_set_cache(date.month) { Period.new(date.beginning_of_month, date.end_of_month) }
  end

  def get_period_week(from)
    get_period(from, from + 6)
  end

  def get_period(from, to)
    get_set_cache([from, to]) { Period.new(from, to) }
  end

  def get_set_cache(key)
    val = @cache[key]
    if val.nil?
      val = yield
      @cache[key] = val
    end
    val
  end

  def is_current_week
    @current.to_s == @todays_week
  end

  def is_current_day
    @current.to_s == @today
  end


  def weekday_header
    names = Date::DAYNAMES[1..6] + [Date::DAYNAMES[0]]
    names.collect! { |n| "<th>#{n[0..1]}</th>" }
    names.join("\n")
  end

  def day_name_header(span = 0)
  	 header = ''
    @graph.each_day do |day|
      header += "<th colspan=\"#{span}\" #{'class="current"' if Date.today == day }>#{Date::DAYNAMES[day.wday][0..1]}</th>\n" unless Holiday.weekend?(day)
    end
    header
  end

  def day_date_header(span = 0)
    header = ''
    @graph.each_day do |day|
      header += "<th colspan=\"#{span}\" #{'class="current"' if Date.today == day }>#{day.mday}</th>\n" unless Holiday.weekend?(day)
    end
    header
  end

  def week_header(span = 0)
    header = ''
    @graph.each_week do |day|
      header += "<th colspan=\"#{span}\">#{'%02d' % day.cweek}</th>\n"
    end
	   header
  end

  def month_header(span_factor = 1)
  	 header = ''
  	 current_month = @graph.period.startDate.month
  	 span = 0
  	 @graph.each_week do |day|
   	  if day.month != current_month
     		 header += append_month(current_month, span * span_factor)
     		 current_month = day.month
     		 span = 0
       end
      span += 1
   	end
  	 header += append_month(current_month, span * span_factor)
  end

  def append_month(current_month, span)
  	 header = "<th colspan=\"#{span}\">"
  	 header += Date::MONTHNAMES[current_month] if span > 2
  	 header += "</th>\n"
  	 header
  end

  def year_header(span_factor = 1)
    header = ''
    current_year = @graph.period.startDate.year
    span = 0
    @graph.each_week do |week|
      if week.year != current_year
        header += append_year(current_year, span * span_factor)
        current_year = week.year
        span = 0
      end
      span += 1
    end
    header += append_year(current_year, span * span_factor)
  end

  def append_year(current_year, span)
    header = "<th colspan=\"#{span}\">"
    header += current_year.to_s if span > 2
    header += "</th>\n"
    header
  end

  def weekbox_td(box, current)
  	 if box
   	  "<td style=\"background-color: #{box.color};\"><a>#{box.height}<span>#{box.tooltip}</span></a></td>"
   	elsif current
      '<td class="current"></td>'
     else
   	   '<td></td>'
 	  end
  end

  def timebox_div(box)
    div = worktime_link box.worktime
    div += image_tag('space.gif',
                     'height' => "#{box.height}px",
                     'style' => "background-color: #{box.color};")
    div += "<span>#{box.tooltip}</span>" unless box.tooltip.strip.empty?
    div += '</a>'
    div
  end

  def worktime_link(worktime)
    if worktime && !worktime.new_record?
      "<a href=\"" + PATH_PREFIX + '/' + worktime.class.name.downcase + "/edit/#{worktime.id}\">"
    else
      '<a>'
    end
  end


  def timebox_div_old(box)
    "<div style=\"background-color: #{box.color}; " \
         "height: #{box.height}pt;\" " +
         "title=\"#{box.tooltip}\"></div>"
  end

  def day_td(date)
    "<td#{Holiday.holiday?(date) ? ' class="holiday"' : ''}>"
  end

end
