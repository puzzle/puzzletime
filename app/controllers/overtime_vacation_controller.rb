class OvertimeVacationController < ManageController

  VALID_GROUPS = [EmployeeController]
  GROUP_KEY = 'otime'

  def editFields
    [[:hours, 'Stunden'],
     [:transfer_date, 'Umgebucht am']]
  end

end
