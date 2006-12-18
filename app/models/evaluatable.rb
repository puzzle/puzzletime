
module Evaluatable 

  def label
    name
  end
   
  def worktimesBy(period = nil, absences = nil, employeeId = 0)
    worktimes.find(:all, 
                   :conditions => conditionsFor(period, {:employee_id => employeeId}, absences), 
                   :order => "work_date ASC, from_start_time ASC")
  end  
  
  def sumWorktime(period = nil, employeeId = 0, absences = nil)
    worktimes.sum(:hours, :conditions => conditionsFor(period, {:employee_id => employeeId}, absences)).to_f
  end
  
  def conditionsFor(period = nil, idHash = {}, absences = nil)
    condArray = [ " 1=1 "]
    if period != nil
      condArray = ["(work_date BETWEEN ? AND ?)", period.startDate, period.endDate]
    end  
    if ! absences.nil?
      condArray[0] += " AND absence_id " + (absences ? "IS NOT NULL " : "IS NULL ")
    end
    idHash.each_pair { |name, id|
      if id > 0 
        condArray[0] += "AND #{name} = ?"
        condArray.push(id)
      end
    }
    condArray
  end    
end 