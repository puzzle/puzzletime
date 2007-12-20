# A Module that provides the funcionality for a model object to be evaluated.
# 
# A class mixin Evaluatable has to provide a has_many relation for worktimes.
# See Evaluation for further details.
module Evaluatable 

  include Comparable
  include Conditioner

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
    options = options.clone
    options[:conditions] = conditionsFor(evaluation, period, categoryRef, 
                                         options[:conditions] ||= nil)
    options[:order] ||= "work_date ASC, project_id, employee_id"
    worktimes.find(:all, options)
  end  
  
  # Sums all worktimes related to this object in a given period.
  def sumWorktime(evaluation, period = nil, categoryRef = false, options = {})
    options = options.clone
    options[:conditions] = conditionsFor(evaluation, period, categoryRef, 
                                         options[:conditions] ||= nil)
    worktimes.sum(:hours, options).to_f
  end
  
  # Counts the number of worktimes related to this object in a given period.
  def countWorktimes(evaluation, period = nil, categoryRef = false, options = {})
    options = options.clone
    options[:conditions] = conditionsFor(evaluation, period, categoryRef)
    worktimes.count("*", options)
  end

  # Raises an Exception if this object has related Worktimes. 
  # This method is a callback for :before_delete.  
  def protect_worktimes
    raise "Diesem Eintrag sind Arbeitszeiten zugeteilt. Er kann nicht entfernt werden." if ! worktimes.empty?
  end  
  
  def <=>(other)
    label_verbose <=> other.label_verbose
  end
  
  def to_s
    label
  end
  
private    
  
  def conditionsFor(evaluation, period = nil, categoryRef = false, condArray = nil)
    condArray = clone_conditions(condArray)
    append_conditions(condArray, ["type = '" + (evaluation.absences? ? 'Absencetime' : 'Projecttime') + "'"])
    append_conditions(condArray, ['work_date BETWEEN ? AND ?', period.startDate, period.endDate]) if period
    append_conditions(condArray, ["? = #{evaluation.categoryRef}", evaluation.category_id]) if categoryRef
    condArray
  end      
  
end 
