# encoding: utf-8


class EmploymentsController < ManageController

  self.nesting = Employee

  self.permitted_attrs = :percent, :start_date, :end_date

end
