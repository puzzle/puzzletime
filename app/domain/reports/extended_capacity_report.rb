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
            'Beschäftigungsgrad (%)',
            'Soll Arbeitszeit (h)',
            'Überstunden (h)',
            'Überstunden Total (h)',
            "Ferienguthaben bis Ende #{@period.end_date.year} (d)",
            'Abwesenheit (h)',
            'Projektkürzel',
            'Projektname',
            'Subprojektname',
            'Projekte Total (h)',
            'Projekte Total - Detail (h)',
            'Stundensatz',
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
      work_items = { billable: [], non_billable: [], internal: [] }
      employee.alltime_leaf_work_items.each do |work_item|
        if internal?(work_item)
          work_items[:internal] << work_item
        elsif work_item.accounting_post.billable
          work_items[:billable] << work_item
        else
          work_items[:non_billable] << work_item
        end
      end

      customer_rows = employee_customer_rows(employee, work_items[:billable] + work_items[:non_billable])
      internal_rows = employee_internal_rows(employee, work_items[:internal])
      all_rows = customer_rows + internal_rows

      csv << employee_summary_row(employee, all_rows)
      all_rows.each { |row| csv << row }
    end
  end

  def employee_summary_row(employee, rows)
    [employee.shortname,
     '',
     employee_average_percents(employee),
     employee.statistics.musttime(@period),
     employee.statistics.overtime(@period),
     employee.statistics.current_overtime(@period.end_date),
     employee_remaining_vacations(employee),
     employee_absences(employee, @period),
     '',
     '',
     '',
     rows.map { |r| r[12] }.sum, # Projekte Total (h)
     '',
     '',
     rows.map { |r| r[15] }.sum, # Kunden-Projekte Total (h)
     '',
     rows.map { |r| r[17] }.sum, # Kunden-Projekte Total verrechenbar (h)
     '',
     rows.map { |r| r[19] }.sum, # Kunden-Projekte Total nicht verrechenbar (h)
     '',
     rows.map { |r| r[21] }.sum, # Interne Projekte Total (h)
     '']
  end

  def employee_customer_rows(employee, work_items)
    rows = []
    work_items.each do |work_item|
      times = find_billable_time(employee, work_item.id, @period)

      billable_hours = extract_billable_hours(times, true)
      non_billable_hours = extract_billable_hours(times, false)

      next unless (billable_hours + non_billable_hours).abs > 0.001
      rows << build_employee_row(employee, work_item,
                                 billable_hours: billable_hours,
                                 non_billable_hours: non_billable_hours)
    end
    rows
  end

  def employee_internal_rows(employee, work_items)
    rows = []
    work_items.each do |work_item|
      times = find_billable_time(employee, work_item.id, @period)

      internal_hours = extract_billable_hours(times, false) +
                       extract_billable_hours(times, true)

      next unless internal_hours.abs > 0.001
      rows << build_employee_row(employee, work_item,
                                 internal_hours: internal_hours)
    end
    rows
  end

  def build_employee_row(employee, work_item, data = {})
    parent = child = work_item
    parent = child.parent if child.parent

    [employee.shortname,
     work_item_department(work_item),
     '',
     '',
     '',
     '',
     '',
     '',
     work_item_code(parent, child),
     work_item_label(parent),
     subwork_item_label(parent, child),
     '',
     data.fetch(:billable_hours, 0) + data.fetch(:non_billable_hours, 0) + data.fetch(:internal_hours, 0),
     offered_rate(work_item),
     '',
     data.fetch(:billable_hours, 0) + data.fetch(:non_billable_hours, 0),
     '',
     data.fetch(:billable_hours, 0),
     '',
     data.fetch(:non_billable_hours, 0),
     '',
     data.fetch(:internal_hours, 0)]
  end

  def internal?(work_item)
    Array.wrap(work_item.path_ids).include?(Company.work_item_id)
  end

  def employee_average_percents(employee)
    employee.statistics.employments_during(@period).sum(&:percent)
  end

  def employee_remaining_vacations(employee)
    employee.statistics.remaining_vacations(Date.new(@period.end_date.year, 12, 31))
  end

  def work_item_code(_work_item, subwork_item)
    subwork_item.path_shortnames
  end

  def work_item_label(work_item)
    work_item.label_verbose
  end

  def offered_rate(work_item)
    work_item.accounting_post.offered_rate
  end

  def work_item_department(work_item)
    work_item.accounting_post.order.department
  end

  def subwork_item_label(work_item, subwork_item)
    subwork_item == work_item ? '' : subwork_item.label
  end
end
