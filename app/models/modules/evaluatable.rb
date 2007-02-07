
module Evaluatable 

  def label
    name
  end
  
  def label_verbose
    label
  end
  
  # Id Symbol of the matching entity
  def partnerId
    :employee_id
  end
     
  def worktimesBy(period = nil, absences = nil, partnerVal = 0, options = {})
    options[:conditions] = conditionsFor(period, {partnerId => partnerVal}, absences)
    options[:order] = "work_date ASC, from_start_time ASC, project_id, employee_id"
    worktimes.find(:all, options)
  end  
  
  def sumWorktime(period = nil, absences = nil, partnerVal = 0)
    worktimes.sum(:hours, 
                  :conditions => conditionsFor(period, {partnerId => partnerVal}, absences)).to_f
  end
  
  def countWorktimes(period = nil, absences = nil, partnerVal = 0)
    worktimes.count(conditionsFor(period, {partnerId => partnerVal}, absences))
  end
  
  def conditionsFor(period = nil, idHash = {}, absences = nil)
    condArray = [ " 1=1 "]
    condArray = ["(work_date BETWEEN ? AND ?)", period.startDate, period.endDate] if ! period.nil?
    condArray[0] += " AND absence_id " + (absences ? "IS NOT NULL " : "IS NULL ") if ! absences.nil?
    idHash.each_pair { |name, id|
      if id > 0 
        condArray[0] += "AND #{name} = ?"
        condArray.push(id)
      end
    }
    return condArray
  end    
  
  def worktimes?
    self.worktimes.size > 0
  end
    
  def protect_worktimes
    raise "Diesem Objekt sind Arbeitszeiten zugeteilt. Es kann nicht entfernt werden." if worktimes?
  end  
  
  def to_s
    label
  end
end 