# Methods added to this helper will be available to all templates in the application.

module ApplicationHelper
  
  def round_hour(hour)
    (hour.to_f * 100).round / 100.0
  end
  
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
  
  def change_date(date)
    date.strftime("%d-%m-%Y")
  end
  
  def detail_employee(projects)
    html = %(<table>)
    for project in projects
      sum_week = 0
      sum_month = 0
      sum_year = 0
      html << %(<tr><td><div id="puzzle">)
      html << "#{project.name}"
      html << %(</div></td><td><div id="puzzle">| Total Project</div></td><td><div id="puzzle"> | Current Week )
      html << "#{Time.now.strftime('%W')}"
      html << %(</div></td><td><div id="puzzle"> | Current Month )
      html << "#{Time.now.strftime('%m')}"
      html << %(</div></td><td><div id="puzzle"> | Current Year</div></td><td><div id="puzzle"> |</div></td></tr>)
      for employee in project.employees
        sum_week = sum_week + project.sumProjectActualWeek(employee.id).to_f
        sum_month = sum_month + project.sumProjectActualMonth(employee.id).to_f
        sum_year = sum_year + project.sumProjectActualYear(employee.id).to_f
        html << %(<tr><td>)
        html << "#{employee.lastname}"
        html << %( )
        html << "#{employee.firstname}"
        html << %(</td><td>| )
        html << "#{project.sumProjectTime(employee.id)}"
        html << %(</td><td>| )
        html << "#{project.sumProjectActualWeek(employee.id)}"
        html << %(</td><td>| )
        html << "#{project.sumProjectActualMonth(employee.id)}"
        html << %(</td><td>| )
        html << "#{project.sumProjectActualYear(employee.id)}"
        html << %(</td><td>|</td></tr>)
      end
      html << %(<tr><td> Total time</td><td>| )
      html << "#{project.sumProjectAllTime}"
      html << %(</td><td>| )
      html << "#{sum_week}"
      html << %(</td><td>| )
      html << "#{sum_month}"
      html << %(</td><td>| )
      html << "#{sum_year}"
      html << %(</td><td>|</td></tr>)
    end
    html << %(</table>)
  end
end
