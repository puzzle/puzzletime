# encoding: utf-8

class OvertimeVacationsController < CrudController

  self.nesting = Employee

  self.permitted_attrs = [:hours, :transfer_date]

end
