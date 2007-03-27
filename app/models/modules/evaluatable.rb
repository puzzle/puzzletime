# A Module that provides the funcionality for a model object to be evaluated.
# 
# A class mixin Evaluatable has to provide a has_many relation for worktimes.
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
     
  # Finds all Worktimes related to this object in a given period.    
  def findWorktimes(evaluation, period = nil, categoryRef = false, options = {})
    options[:conditions] = conditionsFor(evaluation, period, categoryRef)
    options[:order] = "work_date ASC, from_start_time ASC, project_id, employee_id"
    worktimes.find(:all, options)
  end  
  
  # Sums all worktimes related to this object in a given period.
  def sumWorktime(evaluation, period = nil, categoryRef = false, options = {})
    options[:conditions] = conditionsFor(evaluation, period, categoryRef)
    worktimes.sum(:hours, options).to_f
  end
  
  # Counts the number of worktimes related to this object in a given period.
  def countWorktimes(evaluation, period = nil, categoryRef = false, options = {})
    options[:conditions] = conditionsFor(evaluation, period, categoryRef)
    worktimes.count("*", options)
  end

  # Returns whether this object has related Worktimes.
  def worktimes?
    worktimes.size > 0
  end
    
  # Raises an Exception if this object has related Worktimes. 
  # This method is a callback for :before_delete.  
  def protect_worktimes
    raise "Diesem Eintrag sind Arbeitszeiten zugeteilt. Er kann nicht entfernt werden." if worktimes?
  end  
  
  def to_s
    label
  end
  
private    
  
  def conditionsFor(evaluation, period = nil, categoryRef = false)
    condArray = [ (evaluation.absences? ? 'absence_id' : 'project_id') + ' IS NOT NULL ' ]
    if period
      condArray[0] += " AND (work_date BETWEEN ? AND ?) "
      condArray.push period.startDate, period.endDate
    end
    if categoryRef 
      condArray[0] += " AND #{evaluation.categoryRef} = ? "
      condArray.push evaluation.category.id 
    end
    return condArray
  end      
  
end 
