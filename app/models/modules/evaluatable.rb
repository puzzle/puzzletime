
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
     
  def worktimesBy(period = nil, absences = false, partnerVal = 0, options = {})
    options[:conditions] = conditionsFor(period, {partnerId => partnerVal}, absences)
    options[:order] = "work_date ASC, from_start_time ASC, project_id, employee_id"
    worktimes.find(:all, options)
  end  
  
  def sumWorktime(period = nil, absences = false, partnerVal = 0)
    worktimes.sum(:hours, 
                  :conditions => conditionsFor(period, {partnerId => partnerVal}, absences)).to_f
  end
  
  def countWorktimes(period = nil, absences = false, partnerVal = 0)
    worktimes.count("*", 
                    :conditions => conditionsFor(period, {partnerId => partnerVal}, absences))
  end

  def worktimes?
    self.worktimes.size > 0
  end
    
  def protect_worktimes
    raise "Diesem Eintrag sind Arbeitszeiten zugeteilt. Er kann nicht entfernt werden." if worktimes?
  end  
  
  def to_s
    label
  end
  
private    
    
  def conditionsFor(period = nil, idHash = {}, absences = false)
    condArray = [ (absences ? 'absence_id' : 'project_id') + ' IS NOT NULL ' ]
    if ! period.nil?
      condArray[0] += " AND (work_date BETWEEN ? AND ?) "
      condArray.push period.startDate, period.endDate
    end
    idHash.each_pair do |name, id|
      if id > 0 
        condArray[0] += " AND #{name} = ? "
        condArray.push id 
      end
    end
    return condArray
  end    
  
end 