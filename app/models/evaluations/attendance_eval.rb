class AttendanceEval < Evaluation

  DETAIL_COLUMNS   = [:work_date, :hours, :times]
    
  def initialize(employee_id)
    super(Employee.find(employee_id))
  end  
  
  def for?(user)
    self.category == user
  end

  def division_label
    'Anwesenheitszeiten'
  end  
   
  # Sums all worktimes for a given period.
  # If a division is passed or set previously, their sum will be returned.
  # Otherwise the sum of all worktimes in the main category is returned.
  def sum_times(period, div = nil, options = {})
    category.sumAttendance period, options
  end  

  # Sums all worktimes for the category in a given period.
  def sum_total_times(period = nil, options = {})  
    sum_times period, nil, options
  end
    
  # Counts the number of Worktime entries in the current Evaluation for a given period.
  def count_times(period = nil, options = {})
    options = addConditions options, period
    category.attendancetimes.count("*", options).to_i
  end
  
  # Returns a list of all Worktime entries for this Evaluation in the given period
  # of time.
  def times(period, options = {})
    options = addConditions options, period
    options[:order] ||= "work_date ASC, from_start_time"
    category.attendancetimes.find(:all, options)
  end
  
  # Do nothing, attendance has no divisions
  def set_division_id(division_id = nil)
  end
  
  def editLink?(user)
    for? user
  end
 
  def splitLink?(user)
    for? user
  end  
  
  def employee_id
    category.id
  end
  
private

  def addConditions(options = {}, period = nil)
    options = options.clone
    if period
      if options[:conditions]
        options[:conditions] = options[:conditions].clone
        options[:conditions][0] = "(#{options[:conditions][0]}) AND "
      else
        options[:conditions] = ['']
      end
      options[:conditions][0] += "work_date BETWEEN ? AND ?"
      options[:conditions].push period.startDate, period.endDate 
    end
    options
  end  
  
end
