# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

module EvaluatorHelper
      
  def periodLink(period, matrix)
    if period != nil
      html = "Work times during #{period} "
      html += link_to 'Current Period', :action => params[:action], 
                :category => @matrix[:category],
                :division => @matrix[:division]
    else
      html = link_to 'Other Period', 
            :action => 'selectPeriod', 
            :category => @matrix[:category],
            :division => @matrix[:division],
            :return_action => params[:action]
    end  
  end    
      
  def detailLink(category, division, period, id)
    link = "<a href=\"/evaluator/details?category=#{category.class.name}"
    link += "&division=#{division.class.division}&return_action=#{params[:action]}"
    link += "&category_id=#{category.id}&division_id=#{division.id}"
    link += "&start_date=#{period.startDate}&end_date=#{period.endDate}\">"
    link += "<img src =\"/images/lupe.gif\" border=0></a>"
  end
  
  def overview(matrix, id = nil, period = nil)
    if period == nil
      overview_impl(matrix, 
               id, 
               [Period.currentWeek, Period.currentMonth, Period.currentYear],
               ["Current Week: #{Time.now.strftime('%W')}",
                "Current Month: #{Time.now.strftime('%m')}",
                "Current Year: #{Time.now.strftime('%y')}"])
    else
      overview_impl(matrix, id, [period], [period.to_s])
    end   
  end
  
  def overview_impl(matrix, id, periods, periodLabels)
    
    header = %(<td>| Total Project</td>)
    periodLabels.each { |label|
      header += %(<td colspan="2">| #{label}</td>)
    }    
    header += %(<td>|</td>)
    
    html = %(<table>)
    for category in matrix[:category].list(id)
      sum_total = 0 
      sum_periods = Array.new(periods.size, 0)
      html << %(<tr class="times_table_title">)
      html << %(<td>#{category.label}</td>)
      html << header
      html << %(</tr>)
      for division in category.send(@matrix[:division])
        times = periods.collect { |p| division.sumWorktime(p, category.subdivisionRef) }
        total = division.sumWorktime(nil, category.subdivisionRef)
        sum_periods.each_index { |i| sum_periods[i] += times[i] }
        sum_total += total
        
        html << %(<tr><td>#{division.label}</td>)
        html << %(<td>| #{round(total)}</td>)
        periods.each_index { |i| 
          html << %(<td>| #{round(times[i])}</td>)
          html << %(<td align="right">#{detailLink(category, division, periods[i], id)}</td>)
        }
        if category.class == Employee && category == @user
          html << %(<td>| <a href="/worktime/addTime?division=#{division.class.division}&division_id=#{division.id}">)
          html << %(Add Time</a></td>)
        else 
          html << %(<td>|</td>)          
        end
        html << %(</tr>)
      end
      html << %(<tr class="times_total_sum">)
      html << %(<td>Total time</td>)
      html << %(<td>| #{round(sum_total)}</td>)
      sum_periods.each { |sum|
        html << %(<td>| #{round(sum)}</td>)
        html << %(<td></td>)
      }
      html << %(<td>|</td></tr>)
    end
    html << %(</table>)
  end
 
end