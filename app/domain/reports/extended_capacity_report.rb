# encoding: utf-8

class ExtendedCapacityReport < BaseCapacityReport

  def initialize(current_period)
    super(current_period, 'puzzletime_detaillierte_auslastung')
  end

  def to_csv
    CSV.generate do |csv|
      add_header(csv)
      add_employees(csv)
    end
  end

  private

  def add_header(csv)
    csv << ['Mitarbeiter',
            'Auftrag Organisationseinheit',
            'Anstellungsgrad (%)',
            'Soll Arbeitszeit (h)',
            'Überzeit (h)',
            'Überzeit Total (h)',
            "Ferienguthaben bis Ende #{@period.end_date.year} (d)",
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
      work_item_total_billable_hours = 0      # Projekte Total verrechenbar (h)
      work_item_total_non_billable_hours = 0  # Projekte Total nicht verrechenbar (h)
      internal_work_item_total_hours = 0      # Interne Projekte Total (h)

      # split billable and non-billable work_items
      billable_work_items = []
      non_billable_work_items = []

      employee.alltime_leaf_work_items.each do |work_item|
        if work_item.accounting_post.billable
          billable_work_items.push(work_item)
        else
          non_billable_work_items.push(work_item)
        end
      end

      # process billable (customer) work_items
      csv_billable_lines = []
      billable_work_items.each do |work_item|
        times = find_billable_time(employee, work_item.id, @period)
        parent = child = work_item
        parent = child.parent if child.parent

        work_item_billable_hours = extract_billable_hours(times, true)
        work_item_total_billable_hours += work_item_billable_hours
        work_item_non_billable_hours = extract_billable_hours(times, false)
        work_item_total_non_billable_hours += work_item_non_billable_hours

        if (work_item_billable_hours + work_item_non_billable_hours).abs > 0.001
          csv_billable_lines << [employee.shortname, work_item_department(work_item), '', '', '', '', '', '',
                                 work_item_code(parent, child),
                                 work_item_label(parent),
                                 subwork_item_label(parent, child),
                                 '',
                                 work_item_billable_hours + work_item_non_billable_hours,
                                 '',
                                 work_item_billable_hours + work_item_non_billable_hours,
                                 '',
                                 work_item_billable_hours,
                                 '',
                                 work_item_non_billable_hours,
                                 '']
        end
      end

      # process non billable (internal) work_items
      csv_non_billable_lines = []
      non_billable_work_items.each do |work_item|
        times = find_billable_time(employee, work_item.id, @period)
        parent = child = work_item
        parent = child.parent if child.parent

        internal_work_item_hours = extract_billable_hours(times, false)
        internal_work_item_hours += extract_billable_hours(times, true) # hack because there may be entries with wrong $-flag
        internal_work_item_total_hours += internal_work_item_hours

        if internal_work_item_hours.abs > 0.001
          csv_non_billable_lines << [employee.shortname, work_item_department(work_item), '', '', '', '', '', '',
                                     work_item_code(parent, child),
                                     work_item_label(parent),
                                     subwork_item_label(parent, child),
                                     '',
                                     internal_work_item_hours,
                                     '', '', '', '', '', '', '',
                                     internal_work_item_hours]
        end
      end

      work_item_total_hours = work_item_total_billable_hours + work_item_total_non_billable_hours + internal_work_item_total_hours

      average_percents = employee.statistics.employments_during(@period).sum(&:percent)
      remaining_vacations = employee.statistics.remaining_vacations(Date.new(@period.end_date.year, 12, 31))

      # append employee overview
      csv << [employee.shortname,
              '',
              average_percents,
              employee.statistics.musttime(@period),
              employee.statistics.overtime(@period),
              employee.statistics.current_overtime(@period.end_date),
              remaining_vacations,
              employee_absences(employee, @period),
              '',
              '',
              '',
              work_item_total_hours,
              '',
              work_item_total_billable_hours + work_item_total_non_billable_hours,
              '',
              work_item_total_billable_hours,
              '',
              work_item_total_non_billable_hours,
              '',
              internal_work_item_total_hours,
              '']

      # append billable work_item lines
      csv_billable_lines.each do |line|
        csv << line
      end

      # append non-billable work_item lines
      csv_non_billable_lines.each do |line|
        csv << line
      end
    end
  end

  def work_item_code(work_item, subwork_item)
    subwork_item.path_shortnames
  end

  def work_item_label(work_item)
    work_item.label_verbose
  end

  def work_item_department(work_item)
    work_item.accounting_post.order.department
  end

  def subwork_item_label(work_item, subwork_item)
    subwork_item == work_item ? '' : subwork_item.label
  end

end
