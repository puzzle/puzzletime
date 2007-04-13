
class EmploymentController < ManageController

  def modelClass
    Employment
  end
  
  def groupClass
    Employee
  end
  
  def formatColumn(attribute, value)
    return value.to_s + ' %' if :percent == attribute
    super  attribute, value 
  end  
    
  def editFields    
    [[:percent, 'Prozent'],
     [:start_date, 'Start Datum'], 
     [:final, 'End Datum setzen'],
     [:end_date, 'End Datum']]    
  end
  
  def listFields
    [[:start_date, 'Start Datum'], 
     [:end_date, 'End Datum'],
     [:percent, 'Prozent']]   
  end
  
end  