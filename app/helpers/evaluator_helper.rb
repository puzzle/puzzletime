# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

module EvaluatorHelper
      
  def periodLink(period)
    if period != nil
      html = "Work times during #{period} &nbsp; "
      html += link_to 'Current Period', 
                      :action => 'currentPeriod',
                      :return_action => params[:action], 
                      :evaluation => params[:evaluation]
    else
      html = link_to 'Other Period', 
            :action => 'selectPeriod', 
            :return_action => params[:action], 
            :evaluation => params[:evaluation]
    end  
  end    
      
  def detailLink(category_id, division_id, period)
    link = "<a href=\"/evaluator/details?evaluation=#{params[:evaluation]}"
    link += "&category_id=#{category_id}"
    link += "&division_id=#{division_id}" if ! division_id.nil?
    link += "&start_date=#{period.startDate}&end_date=#{period.endDate}\">"
    link += "<img src =\"/images/lupe.gif\" border=0></a>"
  end
  
  def overview(evaluation, period = nil)
    if period == nil
      overview_impl(evaluation,
               [Period.currentWeek, Period.currentMonth, Period.currentYear])
    else
      overview_impl(evaluation, [period])
    end   
  end
  
  def overview_impl(evaluation, periods)    
    header = %(<td>| Total Project</td>)
    periods.each { |period|
      header += %(<td colspan="2">| #{period.label}</td>)
    }    
    header += %(<td>|</td>)
    
    html = %(<table>)
    for category in evaluation.categories
      sum_total = 0 
      sum_periods = Array.new(periods.size, 0)
      html << %(<tr class="times_table_title">)
      html << %(<td>#{category.label}</td>)
      html << header
      html << %(</tr>)
      for division in evaluation.divisions(category)
        times = periods.collect { |p| division.sumWorktime(p, category.subdivisionRef) }
        total = division.sumWorktime(nil, category.subdivisionRef)
        sum_periods.each_index { |i| sum_periods[i] += times[i] }
        sum_total += total
        
        html << %(<tr><td>#{division.label}</td>)
        html << %(<td>| #{round(total)}</td>)
        periods.each_index { |i| 
          html << %(<td>| #{round(times[i])}</td>)
          html << %(<td align="right">#{detailLink(category.id, division.id, periods[i])}</td>)
        }
        if evaluation.for?(@user)
          html << %(<td>| <a href="/worktime/addTime?project_id=#{division.id}">)
          html << %(Add Time</a></td>)
        else 
          html << %(<td>|</td>)          
        end
        html << %(</tr>)
      end
      html << %(<tr class="times_total_sum">)
      html << %(<td>Total time</td>)
      html << %(<td>| #{round(sum_total)}</td>)
      periods.each_index { |i|
        html << %(<td>| #{round(sum_periods[i])}</td>)
        html << %(<td align="right">#{detailLink(category.id, nil, periods[i])}</td>)
      }
      html << %(<td>|</td></tr>)
    end
    html << %(</table>)
  end
 
end