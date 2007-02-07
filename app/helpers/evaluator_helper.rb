# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

module EvaluatorHelper
        
  def init_periods
    @period.nil? ? 
      [Period.currentWeek, Period.currentMonth, Period.currentYear] : 
      [@period]
  end 
  
  def collect_times(periods, sum_periods, division)
    times = periods.collect { |p| @evaluation.sum_times(p, division) }
    times.push(@evaluation.sum_times(nil, division))
    sum_periods.each_index { |i| sum_periods[i] += times[i] }
    times
  end   

  def add_time_link(division = nil)
     addAction = @evaluation.absences? ? 'addAbsence' : 'addTime'
     account = ''
     if division
       account = @evaluation.absences? ? 'absence_id' : 'project_id'
       account = "?#{account}=#{division.id}"
     end  
     "<a href=\"/worktime/#{addAction}#{account}\">Zeit erfassen</a>"  
  end


end