
module Division 

  def label
    name
  end
   
  def detailFor(time)
    ""
  end  
  
  def worktimesBy(period = nil, employeeId = 0)
    worktimes.find(:all, :conditions => conditionsFor(period, :employee_id => employeeId), :order => "work_date ASC")
  end  
  
  def sumWorktime(period = nil, employeeId = 0)
    worktimes.sum(:hours, :conditions => conditionsFor(period, :employee_id => employeeId)).to_f
  end
  
  def conditionsFor(period = nil, idHash = {})
    condArray = [ " 1=1 "]
    if period != nil
      condArray = ["(work_date BETWEEN ? AND ?)", period.startDate, period.endDate]
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