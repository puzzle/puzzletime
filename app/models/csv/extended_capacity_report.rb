# encoding: utf-8

class ExtendedCapacityReport < BaseCapacityReport

  def initialize(current_period)
    super(current_period, 'puzzletime_detaillierte_auslastung')
  end

  def to_csv
    FasterCSV.generate do |csv|
      add_header(csv)
      add_employees(csv)
    end
  end

  private

  def add_header(csv)
    csv << ['Mitarbeiter',
            'Bereich',
            'Anstellungsgrad (%)',
            'Soll Arbeitszeit (h)',
            'Überzeit (h)',
            'Überzeit Total (h)',
            "Ferienguthaben bis Ende #{@period.endDate.year} (d)",
            'Anwesenheit (h)',
            'Zusätzliche Anwesenheit (h)',
            'Abwesenheit (h)',
            'Projektkürzel',
            'Projektname',
            'Subprojektname',
            'Projekte Total (h)',
            'Projekte Total - Detail (h)',
            'Kunden-Projekte Total (h)',
            'Kunden-Projekte Total - Detail (h)',
            'Kunden-Projekte Total verrechenbar (h)',
            'Kunden-Projekte Total verrechenbar - Detail (h)',
            'Kunden-Projekte Total nicht verrechenbar (h)',
            'Kunden-Projekte Total nicht verrechenbar - Detail (h)',
            'Interne Projekte Total (h)',
            'Interne Projekte Total - Detail (h)']
  end

  def add_employees(csv)
    Employee.employed_ones(@period).each do |employee|
      # initialize statistic data
      project_total_billable_hours = 0      # Projekte Total verrechenbar (h)
      project_total_non_billable_hours = 0  # Projekte Total nicht verrechenbar (h)
      internal_project_total_hours = 0      # Interne Projekte Total (h)

      # split billable and non-billable projects
      processed_ids = []
      billable_projects = []
      non_billable_projects = []
      employee.worked_on_projects.each do |project|
        # get id of parent project on (max) level 1
        id = project.path_ids[[1, project.path_ids.size - 1].min]
        unless processed_ids.include? id
          processed_ids.push id
          project = Project.find(id)
          if project.billable
            billable_projects.push project
          else
            non_billable_projects.push project
          end
        end
      end

      # process billable (customer) projects
      csv_billable_lines = []
      billable_projects.each do |project|
        times = find_billable_time(employee, project.id, @period)
        sum = times.collect { |w| w.hours }.sum
        parent = child = project
        parent = child.parent if child.parent

        project_billable_hours = extract_billable_hours(times, true)
        project_total_billable_hours += project_billable_hours
        project_non_billable_hours = extract_billable_hours(times, false)
        project_total_non_billable_hours += project_non_billable_hours

        if (project_billable_hours + project_non_billable_hours).abs > 0.001
          csv_billable_lines << [employee.shortname, '', '', '', '', '', '', '', '', '',
                                 project_code(parent, child),
                                 project_label(parent),
                                 subproject_label(parent, child),
                                 '',
                                 project_billable_hours + project_non_billable_hours,
                                 '',
                                 project_billable_hours + project_non_billable_hours,
                                 '',
                                 project_billable_hours,
                                 '',
                                 project_non_billable_hours,
                                 '']
        end
      end

      # process non billable (internal) projects
      csv_non_billable_lines = []
      non_billable_projects.each do |project|
        times = find_billable_time(employee, project.id, @period)
        sum = times.collect { |w| w.hours }.sum
        parent = child = project
        parent = child.parent if child.parent

        internal_project_hours = extract_billable_hours(times, false)
        internal_project_hours += extract_billable_hours(times, true) # hack because there may be entries with wrong $-flag
        internal_project_total_hours += internal_project_hours

        if internal_project_hours.abs > 0.001
          csv_non_billable_lines << [employee.shortname, '', '', '', '', '', '', '', '', '',
                                     project_code(parent, child),
                                     project_label(parent),
                                     subproject_label(parent, child),
                                     '',
                                     internal_project_hours,
                                     '', '', '', '', '', '', '',
                                     internal_project_hours]
        end
      end

      project_total_hours = project_total_billable_hours + project_total_non_billable_hours + internal_project_total_hours
      attendance_hours = employee.sumAttendance(@period)
      diff = attendance_hours - project_total_hours
      additional_attendance_hours = diff.abs > 0.001 ? diff : 0

      average_percents = employee.statistics.employments_during(@period).sum(&:percent)
      remaining_vacations = employee.statistics.remaining_vacations(Date.new(@period.endDate.year, 12, 31))

      # append employee overview
      csv << [employee.shortname,
              '',
              average_percents,
              employee.statistics.musttime(@period),
              employee.statistics.overtime(@period),
              employee.statistics.current_overtime(@period.endDate),
              remaining_vacations,
              attendance_hours,
              additional_attendance_hours,
              employee_absences(employee, @period),
              '',
              '',
              '',
              project_total_hours,
              '',
              project_total_billable_hours + project_total_non_billable_hours,
              '',
              project_total_billable_hours,
              '',
              project_total_non_billable_hours,
              '',
              internal_project_total_hours,
              '']

      # append billable project lines
      csv_billable_lines.each do |line|
        csv << line
      end

      # append non-billable project lines
      csv_non_billable_lines.each do |line|
        csv << line
      end
    end
  end

  def project_code(project, subproject)
    result = "#{project.client.shortname}-#{project.shortname}"
    result += "-#{subproject.shortname}" if subproject != project
    result
  end

  def project_label(project)
    project.label_verbose
  end

  def subproject_label(project, subproject)
    subproject == project ? '' : subproject.label
  end

end
