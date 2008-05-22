class WorktimeEdit < Splitable
 
  INCOMPLETE_FINISH = false
 
  def addWorktime(worktime)
    if worktime.hours - remainingHours > 0.00001    # we are working with floats: use delta 
      worktime.errors.add(:hours, 'Die gesamte Anzahl Stunden kann nicht vergrössert werden')
    end
    worktime.employee = original.employee
    super(worktime) if worktime.errors.empty?
    return worktime.errors.empty?
  end
  
  def page_title
    "Arbeitszeit von #{original.employee.label} bearbeiten"
  end


end