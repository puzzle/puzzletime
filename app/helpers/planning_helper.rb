module PlanningHelper
  include GraphHelper
  
  # returns weekly overview columns
  def week_overview_tds(overview_graph, colspan = 0)
    result = ''
    overview_graph.each_week do |week|
      result << week_overview_td(overview_graph, week, colspan)
    end
    result
  end
  
  # returns one overview column for a given week 
  def week_overview_td(overview_graph, week, colspan = 0)
    result = "<td colspan=\"#{colspan}\" class=\"#{overview_graph.week_style(week)}\">"
    label = overview_graph.week_label(week)
    
    if colspan > 0
      result <<  label    
    else
      result << "<a href=\"#{url_for(:action => 'employee_planning', :employee_id => overview_graph.employee, :week_date => week)}\">"
      result << "#{overview_graph.planned_days(week)}"
      result << "<span>#{label}</span></a>"
    end
    result << "</td>"
  end

  # returns a weekly planned column
  def week_planning_td(plannings, employee, project, week)
    planning = week_planning(plannings, week, project, employee)
    half_day_with_link_td(employee, week, project)
  end

  # returns daily planned columns
  def day_planning_tds(plannings, employee, project, date)
    current_planning = week_planning(plannings, date, project, employee)
    if current_planning
      planned_half_day_tds(current_planning, date)
    else
      unplanned_half_day_tds(employee, project, date)
    end
  end

  # returns a weekly absence column
  def week_absence_td(absence_graph, date)
    absences = []
    5.times do |day|
      absences << absence_graph.absence(date)
    end
    result = '<td '
    absences.compact!
    if absences.present?
      result << 'class=absence><a>&nbsp;<span>'
      absences.each do |absence|
        result << "#{absence.label}"
      end
    end
    result << "</td>"
  end
  
  # returns daily absence columns
  def day_absence_tds(absence_graph, date)
    result = ''
    5.times do |day|
      absence = absence_graph.absence(date)
      if absence
        result << "<td colspan=2 class=\"absence\"><a>&nbsp;<span>#{absence.label}</span></a></td>"
      else
        result << empty_half_day_td(date)
        result << empty_half_day_td(date)
      end
      date = date.next
    end
    result
  end

  def empty_half_day_td(date)
    "<td #{'class="current"' if Date.today == date } style='width:10px'></td>"
  end

  def half_day_with_link_td(employee, date, project)
    result = "<td #{'class="current"' if Date.today == date } style='width:10px'>"
    result << '<a href="/planning/add?'
    result << "employee_id=#{employee.id}" if employee
    result << "&project_id=#{project.id}" if project
    result << "&date=#{Week::from_date(date).to_integer}\""
    result << ">&nbsp;<span>Neue Planung</span></a>" 
    result << "</td>"
    result
  end

  def planned_half_day_tds(planning, date)
    result = half_day_td(planning, planning.monday_am, date)
    result << half_day_td(planning, planning.monday_pm, date)
    date = date.next
    result << half_day_td(planning, planning.tuesday_am, date)
    result << half_day_td(planning, planning.tuesday_pm, date)
    date = date.next
    result << half_day_td(planning, planning.wednesday_am, date)
    result << half_day_td(planning, planning.wednesday_pm, date)
    date = date.next
    result << half_day_td(planning, planning.thursday_am, date)
    result << half_day_td(planning, planning.thursday_pm, date)
    date = date.next
    result << half_day_td(planning, planning.friday_am, date)
    result << half_day_td(planning, planning.friday_pm, date)
    result
  end
  
  def unplanned_half_day_tds(employee, project, date)
    result = half_day_with_link_td(employee, date, project)
    result << half_day_with_link_td(employee, date, project)
    date = date.next
    result << half_day_with_link_td(employee, date, project)
    result << half_day_with_link_td(employee, date, project)
    date = date.next
    result << half_day_with_link_td(employee, date, project)
    result << half_day_with_link_td(employee, date, project)
    date = date.next
    result << half_day_with_link_td(employee, date, project)
    result << half_day_with_link_td(employee, date, project)
    date = date.next
    result << half_day_with_link_td(employee, date, project)
    result << half_day_with_link_td(employee, date, project)
    result
  end
  
  def half_day_td(planning, planned, date)
    return empty_half_day_td(date) if !planned
    result = '<td class="'
    if planning.definitive
      result << 'definitive' 
    else
      result << 'tentative'
    end
    result << '"><a'
    result << " href=\"/planning/edit/#{planning.id}\">&nbsp;"
    result << '<span>'
    result << "Projekt: #{planning.project.label}<br>"
    result << 'Beschreibung: '
    if planning.description.present?
      result << "#{planning.description}"
    else
      result << '⁻'
    end
    result << "<br>Prozent: #{planning.percent}%"
    result << '</span>'
    result << '</a></td>'
    result
  end
  
private
  # returns the planning record matching the week and project
  def week_planning(plannings, current_week_date, project, employee)
    plannings = plannings.select{|planning| planning.project == project and planning.employee == employee}
    return nil if plannings.empty?
    
    current_week = Week::from_date(current_week_date).to_integer
    plannings.each do |planning|
      return planning if (planning.end_week.nil? && current_week >= planning.start_week) ||
                         (current_week >= planning.start_week && current_week <= planning.end_week)
    end
    nil
  end

end