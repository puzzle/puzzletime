class MultiAbsence
  
  attr_reader :absence_id, :employee, :start_date, :end_date, :description, :worktime
  attr_writer :employee
  
  def attributes=(attr_hash)
    @absence_id = attr_hash[:absence_id]
    @start_date = attr_hash[:start_date]
    @end_date = attr_hash[:end_date]
    @description = attr_hash[:description]
  end
  
  def valid?
    @worktime = worktimeTemplate(@start_date, MUST_HOURS_PER_DAY)
    @worktime.work_date = @end_date if @worktime.valid?
    if valid = @worktime.valid? 
      if period.negative?
        valid = false
        @worktime.errors.add(:work_date, "Das Start Datum muss nach dem End Datum sein")
      end
    end
    valid    
  end
  
  def start_date
    date_or_nil(@start_date)
  end
  
  def end_date
    date_or_nil(@end_date)
  end
  
  def period
    Period.new(@start_date, @end_date)
  end
  
  def errors
    @worktime ? @worktime.errors : []
  end
  
  def save
    count = 0
    period = Period.new(@start_date, @end_date)
    period.step {|date|
      if employment = @employee.employment_at(date)
        must = Holiday.musttime(date) * employment.percentFactor
        if must > 0
          absence = worktimeTemplate(date, must)
          absence.save
          count += 1
        end
      end    
    }    
    count
  end
  
private

  def date_or_nil(value)
    unless value.kind_of? Date
      begin
        value = Date.strptime(value.to_s, DATE_FORMAT)
      rescue 
        value = nil
      end  
    end
    value  
  end

  def worktimeTemplate(date, hours)
    worktime = Absencetime.new
    worktime.report_type = HoursDayType::INSTANCE
    worktime.work_date = date
    worktime.absence_id = @absence_id
    worktime.description = @description
    worktime.employee = @employee
    worktime.hours = hours
    worktime
  end  
  
end