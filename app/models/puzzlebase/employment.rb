module Puzzlebase
  class Employment < Base
    belongs_to :employee,
               :foreign_key => 'FK_EMPLOYEE'
    
    MAPS_TO = ::Employment       
    MAPPINGS = {:percent    => :F_EMPLOYMENT_PERCENT,
                :start_date => :D_START,
                :end_date   => :D_END } 
         
  protected
    
    def self.localFindOptions(original)
      { :include => :employee, 
        :conditions => ["employments.start_date = ? AND employees.shortname = ?", 
                         original.D_START, original.employee.S_SHORTNAME] }
    end
        
    def self.setReference(local, original)
      local.employee_id = ::Employee.find_by_shortname(original.employee.S_SHORTNAME).id
    end    
  end
end