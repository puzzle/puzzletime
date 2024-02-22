# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module Reports
  class RoleDistributionReport
    def initialize(date)
      @date = date
      @filename_prefix = 'puzzletime_funktionsanteile'
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
    end

    def add_header(csv)
      header = [
        Employee.model_name.human,
        'Anstellung',
        'Wertschöpfung'
      ] + categories.map(&:second)
      csv << (["Funktionsanteile per #{format_date_long(@date)}, #{format_business_year(@date)}"] +
             Array.new(header.length - 1, ''))
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
      csv << (["#{Department.model_name.human} #{name}"] + Array.new(categories.length + 2, ''))
    end

    def add_employee(csv, employee)
      csv << ([
        employee.to_s,
        format_percent(employee.current_percent_value),
        format_percent(employee.added_value_percent)
      ] + categories.map { |category_id, _category_name| format_percent(category_percent_for(employee, category_id)) })
      sum_up_employee(employee)
    end

    def add_department_totals(csv, id, name)
      totals = @totals[id]
      add_empty(csv)
      csv << (["Total #{name}", format_percent(totals[:current_percent_value]),
               format_percent(totals[:added_value_percent])] +
             categories.map { |category_id, _category_name| format_percent(totals[:"category_#{category_id}"]) })
    end

    def add_overall_totals(csv)
      add_empty(csv)
      csv << (['', 'Anstellung', 'Wertschöpfung'] +
             categories.map { |_category_id, category_name| category_name })
      csv << (['Total FTE', format_fte(overall_total(:current_percent_value)),
               format_fte(overall_total(:added_value_percent))] +
             categories.map { |category_id, _category_name| format_fte(overall_total(:"category_#{category_id}")) })
    end

    def add_empty(csv)
      csv << Array.new(categories.length + 3, '')
    end

    def category_percent_for(employee, category_id)
      (category_percents[employee.id] || {})[category_id].to_f
    end

    def sum_up_employee(employee)
      totals = @totals[employee.department_id] ||= {}
      %i[current_percent_value added_value_percent].each do |attr|
        totals[attr] = totals[attr].to_f + employee.send(attr).to_f
      end
      categories.each do |(category_id, _)|
        attr = :"category_#{category_id}"
        totals[attr] = totals[attr].to_f + category_percent_for(employee, category_id)
      end
    end

    def overall_total(attr)
      @totals.sum { |_k, v| v[attr] }
    end

    def employees
      @employees ||= Employee.select('employees.id, employees.lastname, employees.firstname, ' \
                                     'department_id, departments.name AS department_name, ' \
                                     'em.percent AS current_percent_value, ' \
                                     'brp.percent AS unbillable_percent, ' \
                                     '(em.percent - COALESCE(brp.percent, 0)) AS added_value_percent')
                             .employed_ones(period)
                             .joins(:department)
                             .joins("LEFT JOIN (#{unbillable_roles_percent.to_sql}) AS brp ON employees.id = brp.id")
                             .reorder('department_name, lastname, firstname')
    end

    def unbillable_roles_percent
      Employee.select('employees.id, SUM(eres.percent) AS percent')
              .employed_ones(period, false)
              .joins('LEFT JOIN employment_roles_employments eres ON (em.id = eres.employment_id)')
              .joins('INNER JOIN employment_roles ers ON (eres.employment_role_id = ers.id AND NOT ers.billable)')
              .group('employees.id')
    end

    def categories
      @categories ||=
        Employee.employed_ones(period)
                .joins('INNER JOIN employment_roles_employments ere ON ere.employment_id = em.id')
                .joins('INNER JOIN employment_roles er ON er.id = ere.employment_role_id')
                .joins('INNER JOIN employment_role_categories erc ON erc.id = er.employment_role_category_id')
                .reorder('erc.name')
                .pluck('erc.id, erc.name')
    end

    def category_percents
      @category_percents ||=
        Employee.employed_ones(period, false)
                .joins('INNER JOIN employment_roles_employments ere ON ere.employment_id = em.id')
                .joins('INNER JOIN employment_roles er ON er.id = ere.employment_role_id')
                .joins('INNER JOIN employment_role_categories erc ON erc.id = er.employment_role_category_id')
                .group('employees.id', 'erc.id')
                .pluck(Arel.sql('employees.id, erc.id, SUM(COALESCE(ere.percent, 0)) AS percent'))
                .each_with_object({}) do |(employee_id, category_id, percent), o|
                  o[employee_id] ||= {}
                  o[employee_id][category_id] = percent
                end
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
      "#{value.to_f.round(2)}%"
    end

    def format_fte(value)
      (value.to_f / 100).round(2)
    end
  end
end
