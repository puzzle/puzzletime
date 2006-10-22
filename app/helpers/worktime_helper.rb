# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

module WorktimeHelper 
   
   # Overview of projects for user and selected period.  
   def overview_user_period(startdate_db, enddate_db, startdate, enddate )
    sum_all_project = 0
    sum_total = 0
    html = %(<table>)
    html << %(<tr><td><div id="puzzle_table_title">Projects</div></td><td><div id="puzzle_table_title">| Total Project </div></td><td><div id="puzzle_table_title">| Date )
    html << "#{startdate}"
    html << %( to )
    html << "#{enddate}"
    html << %(</div></td><td></td><td><div id="puzzle_table_title">|</div></td></tr>)
    for project in @user.projects
      sum_total += project.sumProjectPeriod(@user.id, startdate_db, enddate_db).to_f
      sum_all_project +=  project.sumProjectTime(@user.id).to_f        
      html << %(<tr><td> )
      html << "#{project.name}"
      html << %(</td><td>| )
      html << "#{round(project.sumProjectTime(@user.id))}"
      html << %(</td><td>| )
      html << "#{round(project.sumProjectPeriod(@user.id, startdate_db, enddate_db))}"
          html << %(</td><td><a href="/worktime/showDetailUserPeriod?project_id=)
          html << "#{project.id}"
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
    html << %(<tr><td><div id="puzzle_total_sum"> Total time </div></td><td><div id="puzzle_total_sum">| )
    html << "#{round(sum_all_project)}"
    html << %(</div></td><td><div id="puzzle_total_sum">| )
    html << "#{round(sum_total)}"
    html << %(</div></td><td></td><td><div id="puzzle_total_sum">|</div></td></tr></table>)
  end

  # Overview of projects for user and current time. 
  def overview_user_current(projects)
    sum_all_project = 0 
    sum_week = 0
    sum_month = 0
    sum_year = 0
    html = %(<table><tr><td><div id="puzzle_table_title">Projects</div></td>)
    html << %(<td><div id="puzzle_table_title">| Total Project</div></td>)
    html << %(<td><div id="puzzle_table_title"> | Current Week )
    html << "#{Time.now.strftime('%W')}"
    html << %(</div></td><td></td><td><div id="puzzle_table_title"> | Current Month )
    html << "#{Time.now.strftime('%m')}"
    html << %(</div></td><td></td><td><div id="puzzle_table_title"> | Current Year</div></td><td></td><td><div id="puzzle_table_title"> |</div></td></tr>)
    for project in projects
      sum_week += project.sumProjectCurrentWeek(@user.id).to_f
      sum_month += project.sumProjectCurrentMonth(@user.id).to_f
      sum_year += project.sumProjectCurrentYear(@user.id).to_f   
      sum_all_project +=  project.sumProjectTime(@user.id).to_f
      html << %(<tr><td>)
      html << "#{project.name}"
      html << %(</td><td>| )
      html << "#{round(project.sumProjectTime(@user.id))}"  
      html << %(</td><td>| )
      html << "#{round(project.sumProjectCurrentWeek(@user.id).to_f)}"
        html << %(</td><td><a href="/worktime/showDetailUserWeek?project_id=)
        html << "#{project.id}"
        html << %("><img src ="/images/lupe.gif" border=0></a></td>)
      html << %(<td>| )
      html << "#{round(project.sumProjectCurrentMonth(@user.id).to_f)}"
        html << %(</td><td><a href="/worktime/showDetailUserMonth?project_id=)
        html << "#{project.id}"
        html << %("><img src ="/images/lupe.gif" border=0></a></td>)
      html << %(<td>| )
      html << "#{round(project.sumProjectCurrentYear(@user.id).to_f)}"
        html << %(</td><td><a href="/worktime/showDetailUserYear?project_id=)
        html << "#{project.id}"
        html << %("><img src ="/images/lupe.gif" border=0></a></td>)
      html << %(<td>|<a href="/worktime/addTime?project_id=)
      html << "#{project.id}"
      html << %(">Add Time</a>)
      html << %(</td></tr>)
    end
    html << %(<tr><td><div id="puzzle_total_sum"> Total time </div></td><td><div id="puzzle_total_sum">| )
    html << "#{round(sum_all_project)}"
    html << %(</div></td><td><div id="puzzle_total_sum">| )
    html << "#{round(sum_week)}"
    html << %(</div></td><td></td><td><div id="puzzle_total_sum">| )
    html << "#{round(sum_month)}"
    html << %(</div></td><td></td><td><div id="puzzle_total_sum">| )
    html << "#{round(sum_year)}"
    html << %(</div></td><td></td><td><div id="puzzle_total_sum">|</div></td></tr></table)
  end
  
  # Overview of absence for user and current time.  
  def overview_user_absence_current(absences)
    sum_week = 0
    sum_month = 0
    sum_year = 0
    html = %(<table><tr><td><div id="puzzle_table_title">Absence</div></td>)
    html << %(<td><div id="puzzle_table_title"> | Current Week )
    html << "#{Time.now.strftime('%W')}"
    html << %(</div></td><td></td><td><div id="puzzle_table_title"> | Current Month )
    html << "#{Time.now.strftime('%m')}"
    html << %(</div></td><td></td><td><div id="puzzle_table_title"> | Current Year</td><td></td><td><div id="puzzle_table_title"> |</div></td></tr>)
      for absence in absences
        sum_week += absence.sumAbsenceCurrentWeek(@user.id).to_f
        sum_month += absence.sumAbsenceCurrentMonth(@user.id).to_f
        sum_year += absence.sumAbsenceCurrentYear(@user.id).to_f
        html << %(<tr><td>)
        html << "#{absence.name}"
        html << %(</td><td>| )
        html << "#{round(absence.sumAbsenceCurrentWeek(@user.id).to_f/8)}"
          html << %(</td><td><a href="/evaluator/showDetailAbsenceWeek?absence_id=)
          html << "#{absence.id}"
          html << %(&employee_id=)
          html << "#{@user.id}"
          html << %("><img src ="/images/lupe.gif" border=0></a></td>)
        html << %(<td>| )
        html << "#{round(absence.sumAbsenceCurrentMonth(@user.id).to_f/8)}"
          html << %(</td><td><a href="/evaluator/showDetailAbsenceMonth?absence_id=)
          html << "#{absence.id}"
          html << %(&employee_id=)
          html << "#{@user.id}"
          html << %("><img src ="/images/lupe.gif" border=0></a></td>)
        html << %(<td>| )
        html << "#{round(absence.sumAbsenceCurrentYear(@user.id).to_f/8)}"
          html << %(</td><td><a href="/evaluator/showDetailAbsenceYear?absence_id=)
          html << "#{absence.id}"
          html << %(&employee_id=)
          html << "#{@user.id}"
          html << %("><img src ="/images/lupe.gif" border=0></a></td>)
        html << %(</td><td>|</td></tr>)
      end
      html << %(<tr><td><div id="puzzle_total_sum">Total time</div></td><td><div id="puzzle_total_sum">| )
      html << "#{round(sum_week/8)}"
      html << %(</div></td><td></td><td><div id="puzzle_total_sum">| )
      html << "#{round(sum_month/8)}"
      html << %(</div></td><td></td><td><div id="puzzle_total_sum">| )
      html << "#{round(sum_year/8)}"
      html << %(</div></td><td></td><td><div id="puzzle_total_sum">|</div></td></tr></table>)
  end
  
  # Overview of absence for user and selected period. 
  def overview_user_absence_period(absences, startdate_db, enddate_db, startdate, enddate)
      html = %(<table>)
      sum_total = 0
      html << %(<tr><td><div id="puzzle_table_title">)
      html << "#{@user.lastname}"
      html << %( )
      html << "#{@user.firstname}"
      html << %(</div></td><td><div id="puzzle_table_title"> | Date )
      html << "#{startdate}"
      html << %( to )
      html << "#{enddate}"
      html << %(</div></td><td></td><td><div id="puzzle_table_title"> | </div></td></tr>)
      for absence in absences
        sum_total += absence.sumAbsencePeriod(@user.id, startdate_db, enddate_db).to_f
        html << %(<tr><td>)
        html << "#{absence.name}"
        html << %(</td><td>| )
        html << "#{round(absence.sumAbsencePeriod(@user.id, startdate_db, enddate_db).to_f/8)}"
          html << %(</td><td><a href="/evaluator/showDetailAbsencePeriod?absence_id=)
          html << "#{absence.id}"
          html << %(&employee_id=)
          html << "#{@user.id}"
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
      html << %(</table>)
  end
end
