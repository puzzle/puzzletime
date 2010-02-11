class Puzzlebase::Employment < Puzzlebase::Base
  belongs_to :employee,
             :foreign_key => 'FK_EMPLOYEE'
  
  MAPS_TO = ::Employment       
  MAPPINGS = {:percent    => :F_EMPLOYMENT_PERCENT,
              :start_date => :D_START,
              :end_date   => :D_END } 
       
protected

  def self.updateAll
    ::Employment.delete_all
    super
  end
  
  def self.localFindOptions(original)
    { :include => :employee, 
      :conditions => ["employments.start_date = ? AND employees.shortname = ?", 
                       original.D_START, original.employee.S_SHORTNAME] }
  end
      
  def self.setReference(local, original)
    employee = ::Employee.find_by_shortname(original.employee.S_SHORTNAME)
    local.employee_id = employee.id if employee
  end    
  
  # Saves an update local entry and logs potential error messages.
  def self.saveUpdated(local)
    if local.percent == 0 && local.end_date.nil?
      # do not sync 0% employments with open end dates => corresponds to quitted employee
      true
    else 
      super(local)
    end
  end
end


class Employment < ActiveRecord::Base
  def debugString
    "#{employee.shortname + ':' if employee} #{percent}% vom #{date_label(start_date)} - #{date_label(end_date)}"
  end
end