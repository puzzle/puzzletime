# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class Employment < ActiveRecord::Base
  
  extend Manageable  
  
  attr_accessor :final
  
  # All dependencies between the models are listed below.
  validates_inclusion_of :percent, :in => 0..200, :message => "Die Prozente m&uuml;ssen angegeben werden"
  validates_presence_of :start_date, :message => "Das Start Datum muss angegeben werden"
  
  before_validation :resetEndDate
  before_create :updateEndDate
  belongs_to :employee
  
  before_validation DateFormatter.new('start_date', 'end_date')
  
  def validate    
    if end_date != nil && period && period.negative?
      errors.add_to_base("Die Zeitspanne ist ung&uuml;ltig")
    elsif parallelEmployments?
      errors.add_to_base("F&uuml;r diese Zeitspanne ist bereits eine andere Anstellung definiert") 
    end 
  end
  
  def resetEndDate
    puts final
    write_attribute('end_date', nil) unless final
  end  
 
  def final
    @final = (! end_date.nil?) if @final.nil?
    @final
  end  
  
  def final=(value)
    value = value.to_i > 0 unless value.is_a?(TrueClass) || value.is_a?(FalseClass)
    @final = value
  end
  
  def update_attributes(attr)
    self.final = attr[:final]
    super(attr)
  end
    
  # updates the end date of the previous employement
  def updateEndDate
    previous_employment = Employment.find(:first, :conditions => ["employee_id = ? AND start_date < ? AND end_date IS NULL", employee_id, start_date]) 
    if previous_employment != nil
        previous_employment.end_date = start_date - 1
        previous_employment.save
    end
    later_employment = Employment.find(:first, :conditions => ["employee_id = ? AND start_date > ?", employee_id, start_date], :order => 'start_date') 
    if later_employment != nil
      self.end_date = later_employment.start_date - 1
    end
  end
  
  def period
    return Period.new(start_date, end_date ? end_date : Date.today) if start_date
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
  
  ##### interface methods for Manageable #####     
    
  def label
    "die Anstellung vom #{start_date.strftime('%d.%m.%Y')} - #{end_date ? end_date.strftime('%d.%m.%Y') : 'offen'}"
  end  
    
  def self.labels
    ['Die', 'Anstellung', 'Anstellungen']
  end  
  
  def self.fieldNames    
    [[:percent, 'Prozent'],
     [:start_date, 'Start Datum'], 
     [:final, 'End Datum setzen'],
     [:end_date, 'End Datum']]    
  end
  
  def self.listFields
    [[:start_date, 'Start Datum'], 
     [:end_date, 'End Datum'],
     [:percent, 'Prozent']]   
  end
  
  def self.orderBy 
    'start_date'
  end
 
  def self.columnType(col)
    return :boolean if col == :final
    super(col)
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
         "(start_date <= ? AND (end_date >= ?" + (new_record? ? "" : " OR end_date IS NULL") + ") ) OR" +
        "(start_date <= ? AND (end_date >= ?" + (new_record? ? "" : " OR end_date IS NULL") + ") ) OR " +
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