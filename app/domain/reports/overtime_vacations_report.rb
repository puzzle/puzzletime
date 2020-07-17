class OvertimeVacationsReport
  def initialize(date)
    @date = date
    @filename_prefix = 'puzzletime_überzeit_ferien'
  end

  def filename
    "#{@filename_prefix}_#{format_date_short(@date)}.csv"
  end

  def to_csv
    CSV.generate do |csv|
      add_header(csv)
      add_employees(csv)
    end
  end

  private

  def period
    Period.day_for(@date)
    # @period ||= Period.new(
    #   @employee.employments.minimum(:start_date),
    #   @date
    # )
  end

  def add_header(csv)
    header = [
      Employee.model_name.human,
      'Überzeit',
      'Ferienguthaben',
      'Pensum'
    ]
    csv << ["Überzeit/Ferien per #{format_date_long(@date)}, #{format_business_year(@date)}"] + Array.new(header.length - 1, '')
    csv << header
  end

  def add_employees(csv)
    @totals = {}
    groups = employees.map { |e| [e.department_id, e.department_name] }.uniq
    groups.each do |department_id, department_name|
      add_department(csv, department_name)
      employees.select { |e| e.department_id == department_id }
               .each { |e| add_employee(csv, e) }
      add_department_totals(csv, department_id, department_name)
    end
    add_overall_totals(csv)
  end

  def add_department(csv, name)
    add_empty(csv)
    csv << ["#{Department.model_name.human} #{name}"] + Array.new(3, '')
  end

  def add_employee(csv, employee)
    csv << [
      employee.to_s,
      employee.statistics.current_overtime(@date),
      employee.statistics.remaining_vacations(@date),
      format_percent(employee.current_percent_value)
    ]
    sum_up_employee(employee)
  end

  def add_department_totals(csv, id, name)
    totals = @totals[id]
    add_empty(csv)
    csv << [
      "Total #{name}",
      totals[:current_overtime],
      totals[:remaining_vacations],
      format_percent(totals[:current_percent_value])
    ]
  end

  def add_overall_totals(csv)
    add_empty(csv)
    csv << ["Überzeit/Ferien per #{format_date_long(@date)}, #{format_business_year(@date)}"] + Array.new(3, '')
    csv << ['', 'Überzeit', 'Ferienguthaben', 'Pensum']
    csv << [
      'Total',
      overall_total(:current_overtime),
      overall_total(:remaining_vacations),
      format_percent(overall_total(:current_percent_value))
    ]
  end

  def add_empty(csv, length = 3)
    csv << Array.new(length, '')
  end

  def sum_up_employee(employee)
    totals = @totals[employee.department_id] ||= {}
    totals[:current_overtime] = totals[:current_overtime].to_f + employee.statistics.current_overtime(@date).to_f
    totals[:remaining_vacations] = totals[:remaining_vacations].to_f + employee.statistics.remaining_vacations(@date).to_f
    totals[:current_percent_value] = totals[:current_percent_value].to_f + employee.current_percent_value.to_f
  end

  def overall_total(attr)
    @totals.sum { |_k, v| v[attr] }
  end

  def employees
    @employees ||=
      Employee
      .select(
        :id, :lastname, :firstname, :initial_vacation_days,
        :department_id, 'departments.name AS department_name',
        'em.percent AS current_percent_value'
      )
      .employed_ones(period)
      .joins(:department)
      .reorder(:department_name, :lastname, :firstname)
  end

  def format_date_short(date)
    I18n.l(date, format: '%Y%m%d')
  end

  def format_date_long(date)
    I18n.l(date, format: '%d.%m.%Y')
  end

  def format_business_year(date)
    period = Period.business_year_for(date)
    "GJ #{[period.start_date.year, period.end_date.year].uniq.join('/')}"
  end

  def format_percent(value)
    value.to_f.round(2).to_s + '%'
  end
end
