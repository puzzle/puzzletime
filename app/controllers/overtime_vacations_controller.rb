# encoding: utf-8

class OvertimeVacationsController < ManageController

  self.nesting = Employee

  self.permitted_attrs = [:hours, :transfer_date]

end
