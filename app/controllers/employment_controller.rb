
class EmploymentController < ManageController

  VALID_GROUPS = [EmployeeController] 
  GROUP_KEY = 'employment'

  def formatColumn(attribute, value)
    return value.to_s + ' %' if :percent == attribute
    super  attribute, value 
  end  
    
  def editFields    
    []    
  end
  
  def listFields
    [[:start_date, 'Start Datum'], 
     [:end_date, 'End Datum'],
     [:percent, 'Prozent']]   
  end
  
end  