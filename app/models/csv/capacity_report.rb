class CapacityReport < BaseCapacityReport

  def initialize(period)
    super(period, 'puzzletime_auslastung')
  end

  def to_csv
    FasterCSV.generate do |csv|
      csv << ['Mitarbeiter', 'Projekt', 'Subprojekt', 'Verrechenbar', 'Nicht verrechenbar', 'Monat', 'Jahr']
      Employee.employed_ones(@period).each do |employee|
        monthly_periods.each do |period|
          project_time = 0
          processed_ids = []
          employee.worked_on_projects.each do |project|
            # get id of parent project on (max) level 1
            id = project.path_ids[[1, project.path_ids.size - 1].min]
            unless processed_ids.include? id
              processed_ids.push id
              result = find_billable_time(employee, id, period)
              sum = result.collect { |w| w.hours }.sum
              parent = child = Project.find(id)
              parent = child.parent if child.parent
              append_entry(csv,
                           employee,
                           period,
                           parent.label_verbose,
                           child == parent ? '' : child.label,
                           extract_billable_hours(result, true),
                           extract_billable_hours(result, false))
              project_time += sum
            end
          end
          # include Anwesenheitszeit Differenz
          diff = employee.sumAttendance(period) - project_time
          append_entry(csv, employee, period, 'Zusätzliche Anwesenheit', '', 0, diff)
          # include all absencetimes
          absences = employee_absences(employee, period)
          append_entry(csv, employee, period, 'Abwesenheiten', '', 0, absences)
        end
      end
    end
  end

  private
  def append_entry(csv, employee, period, project_label, subproject_label, billable_hours, not_billable_hours)
    if (billable_hours + not_billable_hours).abs > 0.001
      csv << [employee.shortname,
              project_label,
              subproject_label,
              billable_hours,
              not_billable_hours,
              period.startDate.month,
              period.startDate.year]
    end
  end

  def monthly_periods
    month_end = @period.startDate.end_of_month
    periods = [Period.new(@period.startDate, [month_end, @period.endDate].min)]
    while @period.endDate > month_end
      month_start = month_end + 1
      month_end = month_start.end_of_month
      periods.push Period.new(month_start, [month_end, @period.endDate].min)
    end
    periods
  end

end
