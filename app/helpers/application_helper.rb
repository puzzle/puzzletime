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
  
  def overview_user_period(startdate_db, enddate_db, startdate, enddate )
    sum_all_project = 0
    sum_total = 0
    html = %(<table>)
    html << %(<tr><td><div id="puzzle_table_title">Projects</div></td><td><div id="puzzle_table_title">| Total Project </div></td><td><div id="puzzle_table_title">| Date )
    html << "#{startdate}"
    html << %( to )
    html << "#{enddate}"
    html << %(</div></td><td><div id="puzzle_table_title">|</div></td></tr>)
    for project in @user.projects
      sum_total += project.sumProjectPeriod(@user.id, startdate_db, enddate_db).to_f
      sum_all_project +=  project.sumProjectTime(@user.id).to_f        
      html << %(<tr><td> )
      html << "#{project.name}"
      html << %(</td><td>| )
      html << "#{round_hour(project.sumProjectTime(@user.id))}"
      html << %(</td><td>| )
      html << "#{round_hour(project.sumProjectPeriod(@user.id, startdate_db, enddate_db))}"
      html << %(</td><td>|</td></tr>)
    end
    html << %(<tr><td><div id="puzzle_total_sum"> Total time </div></td><td><div id="puzzle_total_sum">| )
    html << "#{sum_all_project}"
    html << %(</div></td><td><div id="puzzle_total_sum">| )
    html << "#{sum_total}"
    html << %(</div></td><td><div id="puzzle_total_sum">|</div></td></tr></table>)
  end
  
  def overview_employees_period(employees, startdate_db, enddate_db, startdate, enddate)
    html = %(<table>)
    for employee in employees
      sum_all_project = 0 
      sum_total = 0
      html << %(<tr><td><div id="puzzle_table_title">)
      html << "#{employee.lastname}"
      html << %( )
      html << "#{employee.firstname}"
      html << %(</div></td><td><div id="puzzle_table_title">| Total Project</div></td><td><div id="puzzle_table_title"> | Date )
      html << "#{startdate}"
      html << %( )
      html << "#{enddate}"
      html << %(</div></td><td><div id="puzzle_table_title"> |</div></td></tr>)
      for projectmembership in employee.projectmemberships
        sum_all_project += projectmembership.project.sumProjectPeriod(employee.id, startdate_db, enddate_db).to_f  
        sum_total +=  projectmembership.project.sumProjectTime(employee.id).to_f
        html << %(<tr><td>)
        html << "#{projectmembership.project.name}"
        html << %(</td><td>| )
        html << "#{projectmembership.project.sumProjectTime(employee.id)}"
        html << %(</td><td>| )
        html << "#{projectmembership.project.sumProjectPeriod(employee.id, startdate_db, enddate_db)}"
        html << %(</td><td>|</td></tr>)
      end
      html << %(<tr><td><div id="puzzle_total_sum">Total time</div></td><td><div id="puzzle_total_sum">| )
      html << "#{sum_total}"
      html << %(</div></td><td><div id="puzzle_total_sum">| )
      html << "#{sum_all_project}"
      html << %(</div></td><td><div id="puzzle_total_sum">|</div></td></tr>)
    end
    html << %(</table>)
  end
  
  def overview_employees_current(employees)
    html = %(<table>)
    for employee in employees
      sum_all_project = 0 
      sum_week = 0
      sum_month = 0
      sum_year = 0
      html << %(<tr><td><div id="puzzle_table_title">)
      html << "#{employee.lastname}"
      html << %( )
      html << "#{employee.firstname}"
      html << %(</div></td><td><div id="puzzle_table_title">| Total Project</div></td><td><div id="puzzle_table_title"> | Current Week )
      html << "#{Time.now.strftime('%W')}"
      html << %(</div></td><td><div id="puzzle_table_title"> | Current Month )
      html << "#{Time.now.strftime('%m')}"
      html << %(</div></td><td><div id="puzzle_table_title"> | Current Year</td><td><div id="puzzle_table_title"> |</div></td></tr>)
      for projectmembership in employee.projectmemberships
        sum_week += projectmembership.project.sumProjectCurrentWeek(employee.id).to_f
        sum_month += projectmembership.project.sumProjectCurrentMonth(employee.id).to_f
        sum_year += projectmembership.project.sumProjectCurrentYear(employee.id).to_f   
        sum_all_project +=  projectmembership.project.sumProjectTime(employee.id).to_f
        html << %(<tr><td>)
        html << "#{projectmembership.project.name}"
        html << %(</td><td>| )
        html << "#{projectmembership.project.sumProjectTime(employee.id)}"
        html << %(</td><td>| )
        html << "#{projectmembership.project.sumProjectCurrentWeek(employee.id)}"
        html << %(</td><td>| )
        html << "#{projectmembership.project.sumProjectCurrentMonth(employee.id)}"
        html << %(</td><td>| )
        html << "#{projectmembership.project.sumProjectCurrentYear(employee.id)}"
        html << %(</td><td>|</td></tr>)
      end
      html << %(<tr><td><div id="puzzle_total_sum">Total time</div></td><td><div id="puzzle_total_sum">| )
      html << "#{sum_all_project}"
      html << %(</div></td><td><div id="puzzle_total_sum">| )
      html << "#{sum_week}"
      html << %(</div></td><td><div id="puzzle_total_sum">| )
      html << "#{sum_month}"
      html << %(</div></td><td><div id="puzzle_total_sum">| )
      html << "#{sum_year}"
      html << %(</div></td><td><div id="puzzle_total_sum">|</div></td></tr>)
    end
    html << %(</table>)
  end
        
  def overview_user_current(projects)
    sum_all_project = 0 
    sum_week = 0
    sum_month = 0
    sum_year = 0
    html = %(<table><tr><td><div id="puzzle_table_title">Projects</div></td>)
    html << %(<td><div id="puzzle_table_title">| Total Project</div></td>)
    html << %(<td><div id="puzzle_table_title"> | Current Week )
    html << "#{Time.now.strftime('%W')}"
    html << %(</div></td><td><div id="puzzle_table_title"> | Current Month )
    html << "#{Time.now.strftime('%m')}"
    html << %(</div></td><td><div id="puzzle_table_title"> | Current Year</div></td><td><div id="puzzle_table_title"> |</div></td></tr>)
    for project in projects
      sum_week += project.sumProjectCurrentWeek(@user.id).to_f
      sum_month += project.sumProjectCurrentMonth(@user.id).to_f
      sum_year += project.sumProjectCurrentYear(@user.id).to_f   
      sum_all_project +=  project.sumProjectTime(@user.id).to_f
      html << %(<tr><td>)
      html << "#{project.name}"
      html << %(</td><td>| )
      html << "#{project.sumProjectTime(@user.id)}"
      html << %(</td><td>| )
      html << "#{project.sumProjectCurrentWeek(@user.id).to_f}"
      html << %(</td><td>| )
      html << "#{project.sumProjectCurrentMonth(@user.id).to_f}"
      html << %(</td><td>| )
      html << "#{project.sumProjectCurrentYear(@user.id).to_f}"
      html << %(</td><td>|<a href="/worktime/addTime?project_id=)
      html << "#{project.id}"
      html << %(">Add Time</a>)
      html << %(</td></tr>)
    end
    html << %(<tr><td><div id="puzzle_total_sum"> Total time </div></td><td><div id="puzzle_total_sum">| )
    html << "#{sum_all_project}"
    html << %(</div></td><td><div id="puzzle_total_sum">| )
    html << "#{sum_week}"
    html << %(</div></td><td><div id="puzzle_total_sum">| )
    html << "#{sum_month}"
    html << %(</div></td><td><div id="puzzle_total_sum">| )
    html << "#{sum_year}"
    html << %(</div></td><td><div id="puzzle_total_sum">|</div></td></tr></table)
  end
  
  def overview_projectmember_current(projectmemberships)
    html = %(<table>)
    for projectmembership in projectmemberships
      sum_week = 0
      sum_month = 0
      sum_year = 0
      html << %(<tr><td><div id="puzzle_table_title">)
      html << "#{projectmembership.project.name}"
      html << %(</div></td><td><div id="puzzle_table_title">| Total Project</div></td><td><div id="puzzle_table_title"> | Current Week )
      html << "#{Time.now.strftime('%W')}"
      html << %(</div></td><td><div id="puzzle_table_title"> | Current Month )
      html << "#{Time.now.strftime('%m')}"
      html << %(</div></td><td><div id="puzzle_table_title"> | Current Year</div></td><td><div id="puzzle_table_title"> |</div></td></tr>)
      for employee in projectmembership.project.employees
        sum_week += projectmembership.project.sumProjectCurrentWeek(projectmembership.employee.id).to_f
        sum_month += projectmembership.project.sumProjectCurrentMonth(projectmembership.employee.id).to_f
        sum_year += projectmembership.project.sumProjectCurrentYear(projectmembership.employee.id).to_f
        html << %(<tr><td>)
        html << "#{employee.lastname}"
        html << %( )
        html << "#{employee.firstname}"
        html << %(</td><td>| )
        html << "#{projectmembership.project.sumProjectTime(employee.id)}"
        html << %(</td><td>| )
        html << "#{projectmembership.project.sumProjectCurrentWeek(employee.id)}"
        html << %(</td><td>| )
        html << "#{projectmembership.project.sumProjectCurrentMonth(employee.id)}"
        html << %(</td><td>| )
        html << "#{projectmembership.project.sumProjectCurrentYear(employee.id)}"
        html << %(</td><td>|</td></tr>)
      end
      html << %(<tr><td><div id="puzzle_total_sum"> Total time </div></td><td><div id="puzzle_total_sum">| )
      html << "#{projectmembership.project.sumProjectAllTime}"
      html << %(</div></td><td><div id="puzzle_total_sum">| )
      html << "#{sum_week}"
      html << %(</div></td><td><div id="puzzle_total_sum">| )
      html << "#{sum_month}"
      html << %(</div></td><td><div id="puzzle_total_sum">| )
      html << "#{sum_year}"
      html << %(</div></td><td><div id="puzzle_total_sum">|</div></td></tr>)
    end
    html << %(</table>)
  end
   
  def overview_employee_current(projects)
    html = %(<table>)
    for project in projects
      sum_week = 0
      sum_month = 0
      sum_year = 0
      html << %(<tr><td><div id="puzzle_table_title">)
      html << "#{project.name}"
      html << %(</div></td><td><div id="puzzle_table_title">| Total Project</div></td><td><div id="puzzle_table_title"> | Current Week )
      html << "#{Time.now.strftime('%W')}"
      html << %(</div></td><td><div id="puzzle_table_title"> | Current Month )
      html << "#{Time.now.strftime('%m')}"
      html << %(</div></td><td><div id="puzzle_table_title"> | Current Year</div></td><td><div id="puzzle_table_title"> |</div></td></tr>)
      for employee in project.employees
        sum_week += project.sumProjectCurrentWeek(employee.id).to_f
        sum_month += project.sumProjectCurrentMonth(employee.id).to_f
        sum_year += project.sumProjectCurrentYear(employee.id).to_f
        html << %(<tr><td>)
        html << "#{employee.lastname}"
        html << %( )
        html << "#{employee.firstname}"
        html << %(</td><td>| )
        html << "#{project.sumProjectTime(employee.id)}"
        html << %(</td><td>| )
        html << "#{project.sumProjectCurrentWeek(employee.id)}"
        html << %(</td><td>| )
        html << "#{project.sumProjectCurrentMonth(employee.id)}"
        html << %(</td><td>| )
        html << "#{project.sumProjectCurrentYear(employee.id)}"
        html << %(</td><td>|</td></tr>)
      end
      html << %(<tr><td><div id="puzzle_total_sum"> Total time</div> </td><td><div id="puzzle_total_sum">| )
      html << "#{project.sumProjectAllTime}"
      html << %(</div></td><td><div id="puzzle_total_sum">| )
      html << "#{sum_week}"
      html << %(</div></td><td><div id="puzzle_total_sum">| )
      html << "#{sum_month}"
      html << %(</div></td><td><div id="puzzle_total_sum">| )
      html << "#{sum_year}"
      html << %(</div></td><td><div id="puzzle_total_sum">|</div></td></tr>)
    end
    html << %(</table>)
  end
   
  def overview_employee_period(projects, startdate_db, enddate_db, startdate, enddate)
    html = %(<table>)
    for project in projects
      sum_total = 0
      html << %(<tr><td><div id="puzzle_table_title">)
      html << "#{project.name}"
      html << %(</div></td><td><div id="puzzle_table_title">| Total Project </div></td><td><div id="puzzle_table_title">| Date )
      html << "#{startdate}"
      html << %( to )
      html << "#{enddate}"
      html << %(</div></td><td>|</div></td></tr>)
      for employee in project.employees
        sum_total += project.sumProjectPeriod(employee.id, startdate_db, enddate_db).to_f
        html << %(<tr><td>)
        html << "#{employee.lastname}"
        html << %( )
        html << "#{employee.firstname}"
        html << %(</td><td>| )
        html << "#{project.sumProjectTime(employee.id)}"
        html << %(</td><td>| )
        html << "#{project.sumProjectPeriod(employee.id, startdate_db, enddate_db)}"
        html << %(</td><td>|</td></tr>)
      end
      html << %(<tr><td><div id="puzzle_total_sum">Total time</div> </td><td><div id="puzzle_total_sum">| )
      html << "#{project.sumProjectAllTime}"
      html << %(</div></td><td><div id="puzzle_total_sum">| )
      html << "#{sum_total}"
      html << %(</div></td><td><div id="puzzle_total_sum">|</div></td></tr>)
    end
    html << %(</table>)
  end
  
  def overview_projectmember_period(projectmemberships, startdate_db, enddate_db, startdate, enddate)
    html = %(<table>)
    for projectmembership in projectmemberships
      sum_total = 0
      html << %(<tr><td><div id="puzzle_table_title">)
      html << "#{projectmembership.project.name}"
      html << %(</div></td><td><div id="puzzle_table_title">| Total Project </div></td><td><div id="puzzle_table_title">| Date )
      html << "#{startdate}"
      html << %( to )
      html << "#{enddate}"
      html << %(</div></td><td>|</div></td></tr>)
      for employee in projectmembership.project.employees
        sum_total += projectmembership.project.sumProjectPeriod(employee.id, startdate_db, enddate_db).to_f
        html << %(<tr><td>)
        html << "#{employee.lastname}"
        html << %( )
        html << "#{employee.firstname}"
        html << %(</td><td>| )
        html << "#{projectmembership.project.sumProjectTime(employee.id)}"
        html << %(</td><td>| )
        html << "#{projectmembership.project.sumProjectPeriod(employee.id, startdate_db, enddate_db)}"
        html << %(</td><td>|</td></tr>)
      end
      html << %(<tr><td><div id="puzzle_total_sum">Total time</div></td><td><div id="puzzle_total_sum">| )
      html << "#{projectmembership.project.sumProjectAllTime}"
      html << %(</div></td><td><div id="puzzle_total_sum">| )
      html << "#{sum_total}"
      html << %(</div></td><td><div id="puzzle_total_sum">|</div></td></tr>)
    end
    html << %(</table>)
  end
end
