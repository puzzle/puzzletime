# frozen_string_literal: true

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
    return unless can?(:manage, Employment)

    fetch_latest_employment_dates(@employees)
    sort_by_latest_employment(@employees)
  end

  def show
    @employee = Employee.includes(current_employment: {
                                    employment_roles_employments: %i[
                                      employment_role
                                      employment_role_level
                                    ]
                                  })
                        .find(params[:id])
    authorize!(:read, @employee)

    @employee.social_insurance = nil unless can?(:social_insurance, @employee)

    respond_to do |format|
      format.html
      format.vcf { send_data vcard, filename: vcard_filename }
      format.svg { render plain: qr_code.as_svg(fill: 'fff') }
      format.png { render plain: qr_code.as_png(fill: 'fff') }
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
                      employment_roles_employments: %i[
                        employment_role
                        employment_role_level
                      ]
                    })
    else
      list.includes(:department, current_employment: {
                      employment_roles_employments: %i[
                        employment_role
                        employment_role_level
                      ]
                    })
    end
  end

  def fetch_latest_employment_dates(list)
    return if @employee_employment

    @employee_employment = {}
    list.each do |employee|
      @employee_employment[employee] = get_latest_employment(employee).start_date
    end
  end

  def get_latest_employment(employee)
    employments = employee.employments.sort_by(&:start_date).reverse!

    employments.reduce do |newer_employment, older_employment|
      has_gap = newer_employment.start_date - 1.day != older_employment.end_date
      has_gap ? newer_employment : older_employment
    end
  end

  def sort_by_latest_employment(list)
    return unless params[:sort] == 'latest_employment'

    list.sort! { |a, b| @employee_employment[a] <=> @employee_employment[b] }
    return unless params[:sort_dir] == 'asc'

    list.reverse!
  end

  def vcard(include: nil)
    Employees::Vcard.new(@employee, include:).render
  end

  def vcard_filename
    ActiveStorage::Filename.new("#{@employee}.vcf").sanitized
  end

  def qr_code
    vcf = vcard(include: %i[firstname lastname fullname phone_office phone_private email])
    RQRCode::QRCode.new(vcf)
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
