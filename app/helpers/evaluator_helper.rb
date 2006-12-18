# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

module EvaluatorHelper
        
  def init_periods
    if @period.nil?
      [Period.currentWeek, Period.currentMonth, Period.currentYear]
    else
      [@period]
    end
  end 
  
  def collect_times(periods, sum_periods, division)
    times = periods.collect { |p| @evaluation.sum_times(p, division) }
    times.insert(0, @evaluation.sum_times(nil, division))
    sum_periods.each_index { |i| sum_periods[i] += times[i] }
    return times
  end     
  
  def add_time_link(division)
    html = ""
    if @evaluation.for?(@user) 
       html = "<a href=\"/worktime/addTime?" 
       if division.kind_of? Absence
          html += "absence_id=#{division.id}"
       else
          html += "project_id=#{division.id}"
       end 
       html += "\">Add Time</a>"
    end
    return html   
  end

end