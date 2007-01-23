# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class Employment < ActiveRecord::Base
  
  # All dependencies between the models are listed below.
  validates_presence_of :percent, :message => "Die Prozente m&uuml;ssen angegeben werden"
  validates_presence_of :start_date, :message => "Das Start Datum muss angegeben werden"
  
  before_create :updateEndDate
  belongs_to :employee
  
  before_validation DateFormatter.new('start_date', 'end_date')
  
  def validate
    if end_date != nil && period.negative?
      errors.add_to_base("Die Zeitspanne ist ung&uuml;ltig")
    elsif parallelEmployments?
      errors.add_to_base("Eine andere Anstellung ist bereits für diese Zeitspanne definiert") 
    end 
  end
  
  def updateEndDate
    previous_employment = Employment.find(:first, :conditions => ["employee_id = ? AND start_date < ? AND end_date IS NULL", @employee.id, start_date]) 
    if previous_employment != nil
        previous_employment.end_date = start_date - 1
        previous_employment.save
    end
    later_employment = Employment.find(:first, :conditions => ["employee_id = ? AND start_date > ?", @employee.id, start_date], :order => 'start_date') 
    if later_employment != nil
      self.end_date = later_employment.start_date - 1
    end
  end
  
  def period
    return Period.new(start_date, end_date ? end_date : Date.today)
  end
  
  def percentFactor
    percent / 100.0
  end
  
  def vacations
    round2Decimals(period.length / 365.25 * VACATION_DAYS_PER_YEAR * percentFactor)
  end 
    
  def musttime
    period.musttime * percentFactor
  end
  
private
 
  def parallelEmployments?
    conditions = ["employee_id = ? ", employee_id]
    if id != nil
      conditions[0] += " AND id <> ? "
      conditions.push(id)
    end              
    if end_date != nil
      conditions[0] += " AND (" +
         "(start_date <= ? AND (end_date >= ? OR end_date IS NULL) ) OR" +
        "(start_date <= ? AND (end_date >= ? OR end_date IS NULL) ) OR " +
        "(start_date >= ? AND end_date <= ? ))"
      conditions.push(start_date, start_date, end_date, end_date, start_date, end_date)
    else  
      conditions[0] += " AND (start_date = ? OR (start_date <= ? AND end_date >= ?))"
      conditions.push(start_date, start_date, start_date)
    end  
    return Employment.count(:all, :conditions => conditions) > 0
  end

  def round2Decimals(number)  
    (number * 100).round / 100.0
  end
  
end