class WorktimeEdit < Splitable
 
  def addWorktime(worktime)
    if worktime.work_date != original.work_date
      worktime.work_date = original.work_date
      worktime.errors.add(:work_date, 'Das Datum kann nicht geändert werden')
    end
    if remainingHours < worktime.hours
      worktime.errors.add(:hours, 'Die gesamte Anzahl Stunden kann nicht vergrössert werden')
    end
    super(worktime) if worktime.errors.empty?
    return worktime.errors.empty?
  end
  
  def worktimeTemplate
    worktime = super
    worktime.employee_id = original.employee_id
    return worktime
  end

end