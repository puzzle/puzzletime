class ExtendedCapacityReport < BaseCapacityReport
  
  def initialize(current_period)
    super(current_period)
    @filename_prefix = "puzzletime_detaillierte_auslastung"
  end
  
  def to_csv
    FasterCSV.generate do |csv|
      add_header(csv)
      add_employees(csv)
      
    end
  end

private

  def add_header(csv)
      csv << ["Mitarbeiter",
              "Soll Arbeitszeit (h)",
              "Überzeit (h)",
              "Überzeit Total (h)",
              "Ferienguthaben bis Ende #{Date.today.year} (h)",
              "Zusätzliche Anwesenheit (h)",
              "Abwesenheit (h)",
              "Projekte Total (h)",
              "Subprojektname",
              "Projekte Total verrechenbar (h)",
              "Projekte Total nicht verrechenbar (h)",
              "Interne Projekte Total (h)"]
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
        if ! processed_ids.include? id
          processed_ids.push id
          project = Project.find(id)
          if project.billable
            billable_projects.push project
          else
            non_billable_projects.push project
          end
        end 
      end

      csv_billable_lines = process_billable_projects(employee, billable_projects, project_total_billable_hours, project_total_non_billable_hours)
      csv_non_billable_lines = process_non_billable_projects(employee, non_billable_projects, internal_project_total_hours)
    
      project_total_hours = project_total_billable_hours + project_total_non_billable_hours + internal_project_total_hours
      diff = employee.sumAttendance(@period) - project_total_hours
      additional_attendance_hours = diff.abs > 0.001 ? diff : 0
      
      # append employee overview
      csv << [employee.shortname,                                     # Mitarbeiter
              employee.statistics.musttime(@period),                  # Soll Arbeitszeit (h)
              employee.statistics.overtime(@period),                  # Überzeit (h)
              employee.statistics.current_overtime,                   # Überzeit Total (h)
              employee.statistics.current_remaining_vacations,        # Ferienguthaben bis Ende Jahr (h)
              additional_attendance_hours,                            # Zusätzliche Anwesenheit (h)
              employee_absences(employee, @period),                   # Abwesenheit (h)
              project_total_hours,                                    # Projekte Total (h)
              "-",                                                    # Subprojektname
              project_total_billable_hours,                           # Projekte Total verrechenbar (h)
              project_total_non_billable_hours,                       # Projekte Total nicht verrechenbar (h)
              internal_project_total_hours]                           # Interne Projekte Total (h)
      
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
  
  def process_billable_projects(employee, billable_projects, project_total_billable_hours, project_total_non_billable_hours)
    result = []
    billable_projects.each do |project|
      times = find_billable_time(employee, project.id, @period)
      sum = times.collect { |w| w.hours }.sum  
      parent = child = project
      parent = child.parent if child.parent
      
      project_billable_hours = extract_billable_hours(times, true)
      project_total_billable_hours += project_billable_hours
      project_non_billable_hours = extract_billable_hours(times, false)
      project_total_non_billable_hours += project_non_billable_hours
      
      if (project_billable_hours+project_non_billable_hours).abs > 0.001
        result << [employee.shortname, "", "", "", "", "", "",
                parent.label_verbose, 
                child == parent ? "" : child.label,
                project_billable_hours, 
                project_non_billable_hours,
                "-"]
      end
    end
    result
  end

  def process_non_billable_projects(employee, non_billable_projects, internal_project_total_hours)
    result = []
    non_billable_projects.each do |project|
      times = find_billable_time(employee, project.id, @period)
      sum = times.collect { |w| w.hours }.sum  
      parent = child = project
      parent = child.parent if child.parent
      
      internal_project_hours = extract_billable_hours(times, false)
      internal_project_total_hours += internal_project_hours
      
      if internal_project_hours.abs > 0.001
        result << [employee.shortname, "", "", "", "", "", "",
                parent.label_verbose, 
                child == parent ? "" : child.label,
                "-", 
                "-", 
                internal_project_hours]
      end
    end
    result
  end
end