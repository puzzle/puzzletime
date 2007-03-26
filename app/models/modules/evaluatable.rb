# A Module that provides the funcionality for a model object to be evaluated.
# See Evaluation for further details.
module Evaluatable 

  # The displayed label of this object.
  def label
    name
  end
  
  # A more complete label, defaults to the normal label method.
  def label_verbose
    label
  end
  
  # Id Symbol of the matching entity
  def partnerId
    :employee_id
  end
     
  # Finds all Worktimes related to this object in a given period.    
  def worktimesBy(period = nil, absences = false, partnerVal = 0, options = {})
    options[:conditions] = conditionsFor(period, {partnerId => partnerVal}, absences)
    options[:order] = "work_date ASC, from_start_time ASC, project_id, employee_id"
    worktimes.find(:all, options)
  end  
  
  # Sums all worktimes related to this object in a given period.
  def sumWorktime(period = nil, absences = false, partnerVal = 0)
    worktimes.sum(:hours, 
                  :conditions => conditionsFor(period, {partnerId => partnerVal}, absences)).to_f
  end
  
  # Counts the number of worktimes related to this object in a given period.
  def countWorktimes(period = nil, absences = false, partnerVal = 0)
    worktimes.count("*", 
                    :conditions => conditionsFor(period, {partnerId => partnerVal}, absences))
  end

  # Returns whether this object has related Worktimes.
  def worktimes?
    self.worktimes.size > 0
  end
    
  # Raises an Exception if this object has related Worktimes. This method is a callback for :before_delete.  
  def protect_worktimes
    raise "Diesem Eintrag sind Arbeitszeiten zugeteilt. Er kann nicht entfernt werden." if worktimes?
  end  
  
  def to_s
    label
  end
  
private    
    
  def conditionsFor(period = nil, idHash = {}, absences = false)
    condArray = [ (absences ? 'absence_id' : 'project_id') + ' IS NOT NULL ' ]
    if period
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
