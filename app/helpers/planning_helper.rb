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
      result << "<a href=\"#{url_for(action: 'employee_planning', employee_id: overview_graph.employee, week_date: week)}\">"
      result << "#{overview_graph.planned_days(week)}"
      result << "<span>#{label}</span></a>"
    end
    result << '</td>'
  end

  # returns a weekly planned column
  def week_planning_td(plannings, employee, project, week)
    planning = week_planning(plannings, week, project, employee)
    half_day_with_link_td(employee, week, project) # renders a planned cell
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
    result << '</td>'
  end

  # returns a weekly absence column in the project planning graph view
  def week_absence_td_proj(absence_graph, date)
    absences = []
    5.times do |day|
      absences << absence_graph.absence(date)
    end
    result = '<td border=\"0\"'
    absences.compact!
    if absences.present?
      result << 'background-color=\"rgb(204, 204, 255)\"'
      absences.each do |absence|
        result << "#{absence.label}"
      end
    end
    result << '</td>'
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

  # returns daily absence columns in the project planning graph view
  def day_absence_tds_proj(absence_graph, date)
    result = ''
    5.times do |day|
      absence = absence_graph.absence(date)
      if absence
        result << "<td class=\"absence\" border=\"0\" colspan=\"2\"></td>"
      else
        result << empty_half_day_td_absence(date)
        result << empty_half_day_td_absence(date)
      end
      date = date.next
    end
    result
  end

  # draw an empty cell in the planning graph views
  def empty_half_day_td(date)
    "<td #{'class="current"' if Date.today == date } style='width:10px'></td>"
  end

  # draws an empty cell in the thin row for absences in the project planning graph view
  def empty_half_day_td_absence(date)
    "<td #{'class="current"' if Date.today == date } style='width:10px; border-width: 0px 1px 0px 0px'></td>"
  end

  # renders a planned planning cell with a link to the respective project
  def half_day_with_link_td(employee, date, project)
    result = "<td #{'class="current"' if Date.today == date } style='width:10px'>"
    result << '<a href="/planning/add?'
    result << "employee_id=#{employee.id}" if employee
    result << "&project_id=#{project.id}" if project
    result << "&date=#{Week.from_date(date).to_integer}\""
    result << '>&nbsp;<span>Neue Planung</span></a>'
    result << '</td>'
    result
  end

  # render a week with one or more planned half days in the half-day-per-column view
  def planned_half_day_tds(planning, date)
    result = half_day_td(planning, planning.monday_am, date, 1, planning.is_abstract)
    result << half_day_td(planning, planning.monday_pm, date, 1, planning.is_abstract)
    date = date.next
    result << half_day_td(planning, planning.tuesday_am, date, 1, planning.is_abstract)
    result << half_day_td(planning, planning.tuesday_pm, date, 1, planning.is_abstract)
    date = date.next
    result << half_day_td(planning, planning.wednesday_am, date, 1, planning.is_abstract)
    result << half_day_td(planning, planning.wednesday_pm, date, 1, planning.is_abstract)
    date = date.next
    result << half_day_td(planning, planning.thursday_am, date, 1, planning.is_abstract)
    result << half_day_td(planning, planning.thursday_pm, date, 1, planning.is_abstract)
    date = date.next
    result << half_day_td(planning, planning.friday_am, date, 1, planning.is_abstract)
    result << half_day_td(planning, planning.friday_pm, date, 1, planning.is_abstract)
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

  # render a planned halfday in the half-day-per-column view
  def half_day_td(planning, planned, date, colspan, isabstract)
    return empty_half_day_td(date) if !planned && !isabstract
    result = '<td '
    if colspan > 1
      result << "colspan='#{colspan}' "
    end
    result << 'class="'
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
    if isabstract
      result << ' (Prozentplanung)'
    else
      result << ' (Tagesplanung)'
    end
    result << '</span>'
    result << '</a></td>'
    result
  end

  private
  # returns the planning record matching the week and project
  def week_planning(plannings, current_week_date, project, employee)
    plannings = plannings.select { |planning| planning.project == project and planning.employee == employee }
    return nil if plannings.empty?

    current_week = Week.from_date(current_week_date).to_integer
    plannings.each do |planning|
      return planning if (planning.end_week.nil? && current_week >= planning.start_week) ||
                         (current_week >= planning.start_week && current_week <= planning.end_week)
    end
    nil
  end

end
