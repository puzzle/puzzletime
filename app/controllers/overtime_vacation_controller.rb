class OvertimeVacationController < ManageController

  VALID_GROUPS = [EmployeeController]
  GROUP_KEY = 'otime'

  def edit_fields
    [[:hours, 'Stunden'],
     [:transfer_date, 'Umgebucht am']]
  end

end
