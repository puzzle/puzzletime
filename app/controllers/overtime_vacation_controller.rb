class OvertimeVacationController < ManageController

  def modelClass
    OvertimeVacation
  end
  
  def groupClass
    Employee
  end  
    
  def editFields    
    [[:hours, 'Stunden'],
     [:transfer_date, 'Umgebucht am']]    
  end
  
end