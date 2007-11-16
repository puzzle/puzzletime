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
    options[:conditions] = conditionsFor(evaluation, period, categoryRef, 
                                         options[:conditions] ||= nil)
    options[:order] ||= "work_date ASC, project_id, employee_id"
    worktimes.find(:all, options)
  end  
  
  # Sums all worktimes related to this object in a given period.
  def sumWorktime(evaluation, period = nil, categoryRef = false, options = {})
    options[:conditions] = conditionsFor(evaluation, period, categoryRef, 
                                         options[:conditions] ||= nil)
    worktimes.sum(:hours, options).to_f
  end
  
  # Counts the number of worktimes related to this object in a given period.
  def countWorktimes(evaluation, period = nil, categoryRef = false, options = {})
    options[:conditions] = conditionsFor(evaluation, period, categoryRef)
    worktimes.count("*", options)
  end

  # Raises an Exception if this object has related Worktimes. 
  # This method is a callback for :before_delete.  
  def protect_worktimes
    raise "Diesem Eintrag sind Arbeitszeiten zugeteilt. Er kann nicht entfernt werden." if ! worktimes.empty?
  end  
  
  def to_s
    label
  end
  
private    
  
  def conditionsFor(evaluation, period = nil, categoryRef = false, condArray = nil)
    if condArray.nil?
      condArray = [ '' ]
    else
      condArray[0] += " AND "
    end
    condArray[0] += "type = '" + (evaluation.absences? ? 'Absencetime' : 'Projecttime') + "'"
    if period
      condArray[0] += " AND (work_date BETWEEN ? AND ?) "
      condArray.push period.startDate, period.endDate
    end
    if categoryRef 
      condArray[0] += " AND #{evaluation.categoryRef} = ? "
      condArray.push evaluation.category_id 
    end
    return condArray
  end      
  
end 
