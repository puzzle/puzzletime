# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

module EvaluatorHelper
  
  # Overview of all projects for selected period.
  # Group by employees.
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
      html << %( to )
      html << "#{enddate}"
      html << %(</div></td><td></td><td><div id="puzzle_table_title"> |</div></td></tr>)
      for projectmembership in employee.projectmemberships
        sum_all_project += projectmembership.project.sumProjectPeriod(employee.id, startdate_db, enddate_db).to_f  
        sum_total +=  projectmembership.project.sumProjectTime(employee.id).to_f
        html << %(<tr><td>)
        html << "#{projectmembership.project.name}"
        html << %(</td><td>| )
        html << "#{round(projectmembership.project.sumProjectTime(employee.id))}"
        html << %(</td><td>| )
        html << "#{round(projectmembership.project.sumProjectPeriod(employee.id, startdate_db, enddate_db))}"
          html << %(</td><td><a href="/evaluator/showDetailPeriod?project_id=)
          html << "#{projectmembership.project.id}"
          html << %(&employee_id=)
          html << "#{employee.id}"
          html << %(&startdate=)
          html << "#{startdate}"
          html << %(&enddate=)
          html << "#{enddate}"
          html << %(&startdate_db=)
          html << "#{startdate_db}"
          html << %(&enddate_db=)
          html << "#{enddate_db}"
          html << %("><img src ="/images/lupe.gif" border=0></a></td>)
        html << %(</td><td>|</td></tr>)
      end
      html << %(<tr><td><div id="puzzle_total_sum">Total time</div></td><td><div id="puzzle_total_sum">| )
      html << "#{round(sum_total)}"
      html << %(</div></td><td><div id="puzzle_total_sum">| )
      html << "#{round(sum_all_project)}"
      html << %(</div></td><td></td><td><div id="puzzle_total_sum">|</div></td></tr>)
    end
    html << %(</table>)
  end
  
  # Overview of all projects for current time.
  # Group by employees.
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
      html << %(</div></td><td></td><td><div id="puzzle_table_title"> | Current Month )
      html << "#{Time.now.strftime('%m')}"
      html << %(</div></td><td></td><td><div id="puzzle_table_title"> | Current Year</td><td></td><td><div id="puzzle_table_title"> |</div></td></tr>)
      for projectmembership in employee.projectmemberships
        sum_week += projectmembership.project.sumProjectCurrentWeek(employee.id).to_f
        sum_month += projectmembership.project.sumProjectCurrentMonth(employee.id).to_f
        sum_year += projectmembership.project.sumProjectCurrentYear(employee.id).to_f   
        sum_all_project +=  projectmembership.project.sumProjectTime(employee.id).to_f
        html << %(<tr><td>)
        html << "#{projectmembership.project.name}"
        html << %(</td><td>| )
        html << "#{round(projectmembership.project.sumProjectTime(employee.id))}"
        html << %(</td><td>| )
        html << "#{round(projectmembership.project.sumProjectCurrentWeek(employee.id))}"
          html << %(</td><td><a href="/evaluator/showDetailWeek?project_id=)
          html << "#{projectmembership.project.id}"
          html << %(&employee_id=)
          html << "#{employee.id}"
          html << %("><img src ="/images/lupe.gif" border=0></a></td>)
        html << %(<td>| )
        html << "#{round(projectmembership.project.sumProjectCurrentMonth(employee.id))}"
          html << %(</td><td><a href="/evaluator/showDetailMonth?project_id=)
          html << "#{projectmembership.project.id}"
          html << %(&employee_id=)
          html << "#{employee.id}"
          html << %("><img src ="/images/lupe.gif" border=0></a></td>)
        html << %(<td>| )
        html << "#{round(projectmembership.project.sumProjectCurrentYear(employee.id))}"
          html << %(</td><td><a href="/evaluator/showDetailYear?project_id=)
          html << "#{projectmembership.project.id}"
          html << %(&employee_id=)
          html << "#{employee.id}"
          html << %("><img src ="/images/lupe.gif" border=0></a></td>)
        html << %(<td>|</td></tr>)
      end
      html << %(<tr><td><div id="puzzle_total_sum">Total time</div></td><td><div id="puzzle_total_sum">| )
      html << "#{round(sum_all_project)}"
      html << %(</div></td><td><div id="puzzle_total_sum">| )
      html << "#{round(sum_week)}"
      html << %(</div><td></td></td><td><div id="puzzle_total_sum">| )
      html << "#{round(sum_month)}"
      html << %(</div><td></td></td><td><div id="puzzle_total_sum">| )
      html << "#{round(sum_year)}"
      html << %(</div><td></td></td><td><div id="puzzle_total_sum">|</div></td></tr>)
    end
    html << %(</table>)
  end

  # Overview of all employees and current time. 
  # Used for projectmanagement.
  # Group by projects.
  def overview_projectmember_current(projectmemberships)
    html = %(<table>)
    for projectmembership in projectmemberships
      sum_week = 0
      sum_all_project = 0
      sum_month = 0
      sum_year = 0
      html << %(<tr><td><div id="puzzle_table_title">)
      html << "#{projectmembership.project.name}"
      html << %(</div></td><td><div id="puzzle_table_title">| Total Project</div></td><td><div id="puzzle_table_title"> | Current Week )
      html << "#{Time.now.strftime('%W')}"
      html << %(</div></td><td></td><td><div id="puzzle_table_title"> | Current Month )
      html << "#{Time.now.strftime('%m')}"
      html << %(</div></td><td></td><td><div id="puzzle_table_title"> | Current Year</div></td><td></td><td><div id="puzzle_table_title"> |</div></td></tr>)
      for employee in projectmembership.project.employees
        sum_week += projectmembership.project.sumProjectCurrentWeek(employee.id).to_f
        sum_month += projectmembership.project.sumProjectCurrentMonth(employee.id).to_f
        sum_year += projectmembership.project.sumProjectCurrentYear(employee.id).to_f
        sum_all_project += projectmembership.project.sumProjectTime(employee.id).to_f
        html << %(<tr><td>)
        html << "#{employee.lastname}"
        html << %( )
        html << "#{employee.firstname}"
        html << %(</td><td>| )
        html << "#{round(projectmembership.project.sumProjectTime(employee.id))}"
        html << %(</td><td>| )
        html << "#{round(projectmembership.project.sumProjectCurrentWeek(employee.id))}"
          html << %(</td><td><a href="/evaluator/showDetailWeek?project_id=)
          html << "#{projectmembership.project.id}"
          html << %(&employee_id=)
          html << "#{employee.id}"
          html << %("><img src ="/images/lupe.gif" border=0></a></td>)
        html << %(<td>| )
        html << "#{round(projectmembership.project.sumProjectCurrentMonth(employee.id))}"
          html << %(</td><td><a href="/evaluator/showDetailMonth?project_id=)
          html << "#{projectmembership.project.id}"
          html << %(&employee_id=)
          html << "#{employee.id}"
          html << %("><img src ="/images/lupe.gif" border=0></a></td>)
        html << %(<td>| )
        html << "#{round(projectmembership.project.sumProjectCurrentYear(employee.id))}"
          html << %(</td><td><a href="/evaluator/showDetailYear?project_id=)
          html << "#{projectmembership.project.id}"
          html << %(&employee_id=)
          html << "#{employee.id}"
          html << %("><img src ="/images/lupe.gif" border=0></a></td>)
        html << %(<td>|</td></tr>)
      end
      html << %(<tr><td><div id="puzzle_total_sum"> Total time </div></td><td><div id="puzzle_total_sum">| )
      html << "#{round(sum_all_project)}"
      html << %(</div></td><td><div id="puzzle_total_sum">| )
      html << "#{round(sum_week)}"
      html << %(</div></td><td></td><td><div id="puzzle_total_sum">| )
      html << "#{round(sum_month)}"
      html << %(</div></td><td></td><td><div id="puzzle_total_sum">| )
      html << "#{round(sum_year)}"
      html << %(</div></td><td></td><td><div id="puzzle_total_sum">|</div></td></tr>)
    end
    html << %(</table>)
  end
  
  # Overview of all employees and selected period. 
  # Used for projectmanagement.
  # Group by projects.
  def overview_projectmember_period(projectmemberships, startdate_db, enddate_db, startdate, enddate)
    html = %(<table>)
    for projectmembership in projectmemberships
      sum_total = 0
      sum_all_project = 0
      html << %(<tr><td><div id="puzzle_table_title">)
      html << "#{projectmembership.project.name}"
      html << %(</div></td><td><div id="puzzle_table_title">| Total Project </div></td><td><div id="puzzle_table_title">| Date )
      html << "#{startdate}"
      html << %( to )
      html << "#{enddate}"
      html << %(</div></td><td></td><td><div id="puzzle_table_title">|</div></td></tr>)
      for employee in projectmembership.project.employees
        sum_total += projectmembership.project.sumProjectPeriod(employee.id, startdate_db, enddate_db).to_f
        sum_all_project += projectmembership.project.sumProjectTime(employee.id).to_f
        html << %(<tr><td>)
        html << "#{employee.lastname}"
        html << %( )
        html << "#{employee.firstname}"
        html << %(</td><td>| )
        html << "#{round(projectmembership.project.sumProjectTime(employee.id))}"
        html << %(</td><td>| )
        html << "#{round(projectmembership.project.sumProjectPeriod(employee.id, startdate_db, enddate_db))}"
          html << %(</td><td><a href="/evaluator/showDetailPeriod?project_id=)
          html << "#{projectmembership.project.id}"
          html << %(&employee_id=)
          html << "#{employee.id}"
          html << %(&startdate=)
          html << "#{startdate}"
          html << %(&enddate=)
          html << "#{enddate}"
          html << %(&startdate_db=)
          html << "#{startdate_db}"
          html << %(&enddate_db=)
          html << "#{enddate_db}"
          html << %("><img src ="/images/lupe.gif" border=0></a></td>)
        html << %(<td>|</td></tr>)
      end
      html << %(<tr><td><div id="puzzle_total_sum">Total time</div></td><td><div id="puzzle_total_sum">| )
      html << "#{round(sum_all_project)}"
      html << %(</div></td><td><div id="puzzle_total_sum">| )
      html << "#{round(sum_total)}"
      html << %(</div></td><td></td><td><div id="puzzle_total_sum">|</div></td></tr>)
    end
    html << %(</table>)
  end
 
  # Overview of all employees for current time. 
  # Used for management.
  # Group by projects. 
  def overview_employee_current(projects)
    html = %(<table>)
    for project in projects
      sum_week = 0
      sum_month = 0
      sum_year = 0
      sum_all_project = 0
      html << %(<tr><td><div id="puzzle_table_title">)
      html << "#{project.name}"
      html << %(</div></td><td><div id="puzzle_table_title">| Total Project</div></td><td></td><td><div id="puzzle_table_title"> | Current Week )
      html << "#{Time.now.strftime('%W')}"
      html << %(</div></td><td></td><td><div id="puzzle_table_title"> | Current Month )
      html << "#{Time.now.strftime('%m')}"
      html << %(</div></td><td></td><td><div id="puzzle_table_title"> | Current Year</div></td><td></td><td><div id="puzzle_table_title"> |</div></td></tr>)
      for employee in project.employees
        sum_week += project.sumProjectCurrentWeek(employee.id).to_f
        sum_month += project.sumProjectCurrentMonth(employee.id).to_f
        sum_year += project.sumProjectCurrentYear(employee.id).to_f
        sum_all_project += project.sumProjectTime(employee.id).to_f
        html << %(<tr><td>)
        html << "#{employee.lastname}"
        html << %( )
        html << "#{employee.firstname}"
        html << %(</td><td>| )
        html << "#{round(project.sumProjectTime(employee.id))}"
        html << %(</td><td></td><td>| )
        html << "#{round(project.sumProjectCurrentWeek(employee.id))}"
          html << %(</td><td><a href="/evaluator/showDetailWeek?project_id=)
          html << "#{project.id}"
          html << %(&employee_id=)
          html << "#{employee.id}"
          html << %("><img src ="/images/lupe.gif" border=0></a></td>)
        html << %(<td>| )
        html << "#{round(project.sumProjectCurrentMonth(employee.id))}"
           html << %(</td><td><a href="/evaluator/showDetailMonth?project_id=)
           html << "#{project.id}"
           html << %(&employee_id=)
           html << "#{employee.id}"
           html << %("><img src ="/images/lupe.gif" border=0></a></td>)
        html << %(<td>| )
        html << "#{round(project.sumProjectCurrentYear(employee.id))}"
           html << %(</td><td><a href="/evaluator/showDetailYear?project_id=)
           html << "#{project.id}"
           html << %(&employee_id=)
           html << "#{employee.id}"
           html << %("><img src ="/images/lupe.gif" border=0></a></td>)
        html << %(<td>|</td></tr>)
      end
      html << %(<tr><td><div id="puzzle_total_sum"> Total time</div> </td><td><div id="puzzle_total_sum">| )
      html << "#{round(sum_all_project)}"
      html << %(</div></td><td></td><td><div id="puzzle_total_sum">| )
      html << "#{round(sum_week)}"
      html << %(</div></td><td></td><td><div id="puzzle_total_sum">| )
      html << "#{round(sum_month)}"
      html << %(</div></td><td></td><td><div id="puzzle_total_sum">| )
      html << "#{round(sum_year)}"
      html << %(</div></td><td></td><td><div id="puzzle_total_sum">|</div></td></tr>)
    end
    html << %(</table>)
  end

  # Overview of all employees for project in selected period. 
  # Used for management.
  # Group by projects. 
  def overview_employee_period(projects, startdate_db, enddate_db, startdate, enddate)
    html = %(<table>)
    for project in projects
      sum_total = 0
      sum_all_project = 0
      html << %(<tr><td><div id="puzzle_table_title">)
      html << "#{project.name}"
      html << %(</div></td><td><div id="puzzle_table_title">| Total Project </div></td><td><div id="puzzle_table_title">| Date )
      html << "#{startdate}"
      html << %( to )
      html << "#{enddate}"
      html << %(</div></td><td></td><td><div id="puzzle_table_title">|</div></td></tr>)
      for employee in project.employees
        sum_total += project.sumProjectPeriod(employee.id, startdate_db, enddate_db).to_f
        sum_all_project += project.sumProjectTime(employee.id).to_f
        html << %(<tr><td>)
        html << "#{employee.lastname}"
        html << %( )
        html << "#{employee.firstname}"
        html << %(</td><td>| )
        html << "#{round(project.sumProjectTime(employee.id))}"
        html << %(</td><td>| )
        html << "#{round(project.sumProjectPeriod(employee.id, startdate_db, enddate_db))}"
          html << %(</td><td><a href="/evaluator/showDetailPeriod?project_id=)
          html << "#{project.id}"
          html << %(&employee_id=)
          html << "#{employee.id}"
          html << %(&startdate=)
          html << "#{startdate}"
          html << %(&enddate=)
          html << "#{enddate}"
          html << %(&startdate_db=)
          html << "#{startdate_db}"
          html << %(&enddate_db=)
          html << "#{enddate_db}"
          html << %("><img src ="/images/lupe.gif" border=0></a></td>)
        html << %(<td>|</td></tr>)
      end
      html << %(<tr><td><div id="puzzle_total_sum">Total time</div> </td><td><div id="puzzle_total_sum">| )
      html << "#{round(sum_all_project)}"
      html << %(</div></td><td><div id="puzzle_total_sum">| )
      html << "#{round(sum_total)}"
      html << %(</div></td><td></td><td><div id="puzzle_total_sum">|</div></td></tr>)
    end
    html << %(</table>)
  end
  
  # Overview of all projects and selected period from clients.
  def overview_client_period(clients, startdate_db, enddate_db, startdate, enddate)
    html = %(<table>)
    for client in clients  
      sum_total = 0
      sum_period = 0 
      html << %(<tr><td><div id="puzzle_table_title">)
      html << "#{client.name}"
      html << %(</div></td><td><div id="puzzle_table_title"> | Total Time )
      html << %(</div></td><td><div id="puzzle_table_title"> | Date )
      html << "#{startdate}"
      html << %( to )
      html << "#{enddate}"
      html << %(</div></td><td><div id="puzzle_table_title"> |</div></td></tr>) 
      for project in client.projects
        sum_period += project.sumProjectPeriodForClient(startdate_db, enddate_db).to_f
        sum_total += project.sumProjectTotal.to_f
        html << %(<tr><td>)
        html << "#{project.name}"
        html << %(</td><td>| )
        html << "#{round(project.sumProjectTotal.to_f)}"
        html << %(</td><td>| )
        html << "#{round(project.sumProjectPeriodForClient(startdate_db, enddate_db).to_f)}"
        html << %(</td><td>|</td></tr>)
      end
      html << %(<tr><td><div id="puzzle_total_sum">Total time</div></td><td><div id="puzzle_total_sum">| )
      html << "#{round(sum_total)}"
      html << %(</div></td><td><div id="puzzle_total_sum">| )
      html << "#{round(sum_period)}"
      html << %(</div></td><td><div id="puzzle_total_sum">|</div></td></tr>)
    end
    html << %(</table>)
  end
  
  # Overview of all projects and current time from clients.
  def overview_client_current(clients)
    html = %(<table>)
    for client in clients  
      sum_week = 0
      sum_month = 0
      sum_year = 0 
      sum_total = 0
      html << %(<tr><td><div id="puzzle_table_title">)
      html << "#{client.name}"
      html << %(</div></td><td><div id="puzzle_table_title"> | Total Time )
      html << %(</div></td><td><div id="puzzle_table_title"> | Current Week )
      html << "#{Time.now.strftime('%W')}"
      html << %(</div></td><td><div id="puzzle_table_title"> | Current Month )
      html << "#{Time.now.strftime('%m')}"
      html << %(</div></td><td><div id="puzzle_table_title"> | Current Year</td><td><div id="puzzle_table_title"> |</div></td></tr>) 
      for project in client.projects
        sum_week += project.sumProjectWeek.to_f
        sum_month += project.sumProjectMonth.to_f
        sum_year += project.sumProjectYear.to_f
        sum_total += project.sumProjectTotal.to_f
        html << %(<tr><td>)
        html << "#{project.name}"
        html << %(</td><td>| )
        html << "#{round(project.sumProjectTotal.to_f)}"
        html << %(</td><td>| )
        html << "#{round(project.sumProjectWeek.to_f)}"
        html << %(</td><td>| )
        html << "#{round(project.sumProjectMonth.to_f)}"
        html << %(</td><td>| )
        html << "#{round(project.sumProjectYear.to_f)}"
        html << %(</td><td>|</td></tr>)
      end
      html << %(<tr><td><div id="puzzle_total_sum">Total time</div></td><td><div id="puzzle_total_sum">| )
      html << "#{round(sum_total)}"
      html << %(</div></td><td><div id="puzzle_total_sum">| )
      html << "#{round(sum_week)}"
      html << %(</div></td><td><div id="puzzle_total_sum">| )
      html << "#{round(sum_month)}"
      html << %(</div></td><td><div id="puzzle_total_sum">| )
      html << "#{round(sum_year)}"
      html << %(</div></td><td><div id="puzzle_total_sum">|</div></td></tr>)
    end
    html << %(</table>)
  end
  
  #Overview of all absences for current time.
  #Group by employees.
  def overview_absence_current(employees, absences)
    html = %(<table>)
    for employee in employees
      sum_week = 0
      sum_month = 0
      sum_year = 0
      html << %(<tr><td><div id="puzzle_table_title">)
      html << "#{employee.lastname}"
      html << %( )
      html << "#{employee.firstname}"
      html << %(</div></td><td><div id="puzzle_table_title"> | Current Week )
      html << "#{Time.now.strftime('%W')}"
      html << %(</div></td><td></td><td><div id="puzzle_table_title"> | Current Month )
      html << "#{Time.now.strftime('%m')}"
      html << %(</div></td><td></td><td><div id="puzzle_table_title"> | Current Year</td><td></td><td><div id="puzzle_table_title"> |</div></td></tr>)
      for absence in absences
        sum_week += absence.sumAbsenceCurrentWeek(employee.id).to_f
        sum_month += absence.sumAbsenceCurrentMonth(employee.id).to_f
        sum_year += absence.sumAbsenceCurrentYear(employee.id).to_f
        html << %(<tr><td>)
        html << "#{absence.name}"
        html << %(</td><td>| )
        html << "#{round(absence.sumAbsenceCurrentWeek(employee.id).to_f/8)}"
          html << %(</td><td><a href="/evaluator/showDetailAbsenceWeek?absence_id=)
          html << "#{absence.id}"
          html << %(&employee_id=)
          html << "#{employee.id}"
          html << %("><img src ="/images/lupe.gif" border=0></a></td>)
        html << %(<td>| )
        html << "#{round(absence.sumAbsenceCurrentMonth(employee.id).to_f/8)}"
          html << %(</td><td><a href="/evaluator/showDetailAbsenceMonth?absence_id=)
          html << "#{absence.id}"
          html << %(&employee_id=)
          html << "#{employee.id}"
          html << %("><img src ="/images/lupe.gif" border=0></a></td>)
        html << %(<td>| )
        html << "#{round(absence.sumAbsenceCurrentYear(employee.id).to_f/8)}"
          html << %(</td><td><a href="/evaluator/showDetailAbsenceYear?absence_id=)
          html << "#{absence.id}"
          html << %(&employee_id=)
          html << "#{employee.id}"
          html << %("><img src ="/images/lupe.gif" border=0></a></td>)
        html << %(<td>|</td></tr>)
      end
      html << %(<tr><td><div id="puzzle_total_sum">Total time</div></td><td><div id="puzzle_total_sum">| )
      html << "#{round(sum_week/8)}"
      html << %(</div></td><td></td><td><div id="puzzle_total_sum">| )
      html << "#{round(sum_month/8)}"
      html << %(</div></td><td></td><td><div id="puzzle_total_sum">| )
      html << "#{round(sum_year/8)}"
      html << %(</div></td><td></td><td><div id="puzzle_total_sum">|</div></td></tr>)
    end
    html << %(</table>)
  end
  
  #Overview of all absences for selected period.
  #Group by employees.
  def overview_absence_period(employees, absences, startdate_db, enddate_db, startdate, enddate)
    html = %(<table>)
    for employee in employees
      sum_total = 0
      html << %(<tr><td><div id="puzzle_table_title">)
      html << "#{employee.lastname}"
      html << %( )
      html << "#{employee.firstname}"
      html << %(</div></td><td><div id="puzzle_table_title"> | Date )
      html << "#{startdate}"
      html << %( to )
      html << "#{enddate}"
      html << %(</div></td><td></td><td><div id="puzzle_table_title"> | </div></td></tr>)
      for absence in absences
        sum_total += absence.sumAbsencePeriod(employee.id, startdate_db, enddate_db).to_f
        html << %(<tr><td>)
        html << "#{absence.name}"
        html << %(</td><td>| )
        html << "#{round(absence.sumAbsencePeriod(employee.id, startdate_db, enddate_db).to_f/8)}"
          html << %(</td><td><a href="/evaluator/showDetailAbsencePeriod?absence_id=)
          html << "#{absence.id}"
          html << %(&employee_id=)
          html << "#{employee.id}"
          html << %(&startdate=)
          html << "#{startdate}"
          html << %(&enddate=)
          html << "#{enddate}"
          html << %(&startdate_db=)
          html << "#{startdate_db}"
          html << %(&enddate_db=)
          html << "#{enddate_db}"
          html << %("><img src ="/images/lupe.gif" border=0></a></td>)
        html << %(<td>|</td></tr>)
      end
      html << %(<tr><td><div id="puzzle_total_sum">Total time</div></td><td><div id="puzzle_total_sum">| )
      html << "#{round(sum_total/8)}"
      html << %(</div></td><td></td><td><div id="puzzle_total_sum">|</div></td></tr>)
    end
    html << %(</table>)
  end 
end