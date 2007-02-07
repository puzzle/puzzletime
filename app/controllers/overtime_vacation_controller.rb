class OvertimeVacationController < ApplicationController

  include ManageModule

  # Checks if employee came from login or from direct url
  before_filter :authorize
  
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