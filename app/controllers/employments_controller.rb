# encoding: utf-8

class EmploymentsController < ManageController
  self.nesting = Employee

  self.permitted_attrs = :percent, :start_date, :end_date, :probation_period_end_date,
    :vacation_days_per_year, :comment
end
