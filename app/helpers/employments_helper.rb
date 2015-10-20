# encoding: UTF-8

module EmploymentsHelper
  def format_employment_percent(employment)
    p = employment.percent
    "#{p == p.to_i ? p.to_i : p} %"
  end
end
