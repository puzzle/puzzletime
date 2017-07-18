# encoding: utf-8

module EmployeeMasterDataHelper
  def format_latest_employment(employee)
    get_latest_employment_date(employee)
  end

  def format_year_of_service(employee)
    Time.zone.now.year - get_latest_employment_date(employee).year
  end

  private

  def get_latest_employment_date(employee)
    employment = employee.employments.find do |e|
      next unless e.end_date

      start_date = e.end_date - 1.day

      employee.employments.find { |em| em.start_date == start_date }
    end
    employment ||= employee.employments.last
    employment.start_date
  end
end
