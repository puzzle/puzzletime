class EmployeeStatistics

  attr_reader :employee
  
  def initialize(employee) 
    @employee = employee
  end
  
  
  #########  vacation information ############
  
  # Returns the unused days of vacation remaining until the end of the current year.
  def current_remaining_vacations
     remaining_vacations(Date.new(Date.today.year, 12, 31))
  end
  
  # Returns the unused days of vacation remaining until the given date.
  def remaining_vacations(date)
    period = employment_period_to(date)
    @employee.initial_vacation_days + total_vacations(period) + 
      overtime_vacation_hours(date) / 8.0 - used_vacations(period)
  end
  
  # Returns the overall amount of granted vacation days for the given period.
  def total_vacations(period)
    employments_during(period).sum(&:vacations).to_f
  end
  
  # Returns the used vacation days for the given period
  def used_vacations(period)
    return 0 if period.nil?
    @employee.worktimes.sum(:hours, :conditions => ["absence_id = ? AND (work_date BETWEEN ? AND ?)", 
      VACATION_ID, period.startDate, period.endDate]).to_f / 8.0
  end
  
  
  ###########  overtime information  ###################
  
  # Returns the overall overtime hours until the given date.
  # Default is yesterday.   
  def current_overtime(date = Date.today - 1)
    overtime(employment_period_to(date)) - overtime_vacation_hours
  end
  
  # Returns the overtime hours worked in the given period.
  def overtime(period)
     payed_worktime(period) - musttime(period)
  end
  
  # Returns the hours this employee has to work in the given period.
  def musttime(period)
     employments_during(period).sum(&:musttime)
  end  
  

private

    # Returns the hours this employee worked plus the payed absences for the given period.
  def payed_worktime(period)
    condArray = ["((project_id IS NULL AND absence_id IS NULL) OR absences.payed)"]
    if period
      condArray[0] += " AND (work_date BETWEEN ? AND ?)"    
      condArray.push period.startDate
      condArray.push period.endDate
    end      
    @employee.worktimes.sum(:hours, 
                            :joins => 'LEFT JOIN absences ON absences.id = absence_id',
                            :conditions => condArray).to_f
  end
  
  # Return the overtime hours that were transformed into vacations up to the given date.
  def overtime_vacation_hours(date = nil)    
    @employee.overtime_vacations.sum(:hours,
                                     :conditions => date ? ['transfer_date <= ?', date] : nil).to_f
  end


  ######### employment helpers ######################  
  
  # Returns an Array of all employements during the given period, 
  # an empty Array if no employments exist.
  def employments_during(period)
    return [] if period.nil?
    selectedEmployments = @employee.employments.find(:all, 
        :conditions => ["(end_date IS NULL OR end_date >= ?) AND start_date <= ?", 
          period.startDate, period.endDate],
        :order => 'start_date')
    unless selectedEmployments.empty?
      selectedEmployments.first.start_date = period.startDate if selectedEmployments.first.start_date < period.startDate
      if selectedEmployments.last.end_date == nil ||
         selectedEmployments.last.end_date > period.endDate then
        selectedEmployments.last.end_date = period.endDate
      end  
    end
    selectedEmployments    
  end
  
  # Returns the Period from the first employement date until the given period.
  # Returns nil if no employments exist until this date.  
  def employment_period_to(date)
    first_employment = @employee.employments.find(:first, :order => 'start_date ASC')
    return nil if first_employment == nil || first_employment.start_date > date
    Period.retrieve(first_employment.start_date, date)
  end
  
  
end