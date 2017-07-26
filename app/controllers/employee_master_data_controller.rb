# encoding: utf-8

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


class EmployeeMasterDataController < ApplicationController

  delegate :model_class, to: 'self.class'

  helper_method :model_class

  class << self
    def model_class
      Employee
    end
  end

  def index
    authorize!(:read, Employee)
    @employees = list_entries.to_a
    if can?(:manage, Employment)
      fetch_latest_employment_dates(@employees)
      sort_by_latest_employment(@employees)
    end
  end

  def show
    @employee = Employee.includes(current_employment: {
                                    employment_roles_employments: [
                                      :employment_role,
                                      :employment_role_level
                                    ]
                                  })
                        .find(params[:id])
    authorize!(:read, @employee)

    respond_to do |format|
      format.html
      format.vcf
      format.svg { render plain: qr_code.as_svg }
    end
  end

  private

  def list_entries
    list_entries_includes(
      Employee.select('employees.*, ' \
                      'em.percent AS current_percent_value, ' \
                      'departments.name, ' \
                      'CONCAT(lastname, \' \', firstname) AS fullname')
      .employed_ones(Period.current_day)
      .joins('LEFT JOIN departments ON departments.id = employees.department_id')
    ).list
  end

  def list_entries_includes(list)
    if can?(:manage, Employment)
      list.includes(:department, :employments, current_employment: {
        employment_roles_employments: [
          :employment_role,
          :employment_role_level
        ]
      })
    else
      list.includes(:department, current_employment: {
        employment_roles_employments: [
          :employment_role,
          :employment_role_level
        ]
      })
    end
  end

  def fetch_latest_employment_dates(list)
    return if @employee_employment

    @employee_employment = {}
    list.each do |employee|
      @employee_employment[employee] = get_latest_employment_date(employee)
    end
  end

  def get_latest_employment_date(employee)
    employment = employee.employments.find do |e|
      next unless e.end_date

      start_date = e.end_date - 1.day

      employee.employments.find { |em| em.start_date == start_date }
    end
    employment ||= employee.employments.last
    employment.start_date
  end

  def sort_by_latest_employment(list)
    if params[:sort] == 'latest_employment'
      list.sort! { |a, b| @employee_employment[a] <=> @employee_employment[b] }
      if params[:sort_dir] == 'asc'
        list.reverse!
      end
    end
  end

  def qr_code
    RQRCode::QRCode.new(employee_master_datum_url(id: params[:id], format: :vcf))
  end

  # Must be included after the #list_entries method is defined.
  include DryCrud::Searchable
  include DryCrud::Sortable

  # Must be defined after searchable/sortable modules have been included.
  self.search_columns = ['lastname', 'firstname', 'shortname', 'departments.name']
  self.sort_mappings_with_indifferent_access = {
    department: 'departments.name',
    fullname: 'fullname',
    current_percent_value: 'current_percent_value'
  }.with_indifferent_access

end
