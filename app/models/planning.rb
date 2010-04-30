class Planning < ActiveRecord::Base

  validates_presence_of :employee_id, :project_id, :start_week
  
  belongs_to :project
  belongs_to :employee
  
  def start_week_date
    Week::from_integer(start_week).to_date if valid_week?(start_week)
  end

  def end_week_date
      Week::from_integer(end_week).to_date if !end_week.nil? && valid_week?(end_week)
  end
  
  def repeat_type_no?
    end_week == start_week
  end
  
  def repeat_type_until?
    end_week.present? && end_week > start_week
  end
  
  def repeat_type_forever?
    end_week.nil?  
  end
  
  def planned_during?(period)
    if repeat_type_forever?
      return period.endDate >= start_week_date
    end
    !((period.startDate < start_week_date && period.endDate < start_week_date) || (period.startDate > end_week_date && period.endDate > end_week_date))
  end

  def validate
    errors.add(:start_week, "Von Format ist ung&uuml;ltig") if !valid_week?(start_week)
    errors.add(:end_week, "Bis Format ist ung&uuml;ltig") if end_week && !valid_week?(end_week)

    if !(monday_am || monday_pm || tuesday_am || tuesday_pm || wednesday_am || wednesday_pm || thursday_am || thursday_pm || friday_am || friday_pm)
      errors.add(:start_date, "Mindestens ein halber Tag muss selektiert werden")
    end
    
    existing_plannings = Planning.find(:all, :conditions => ['project_id = ? and employee_id = ?', project_id, employee_id]) #todo: limit search result by date
    existing_plannings.each do |planning|
      if overlaps?(planning)
        errors.add(:start_date, "Dieses Projekt ist in diesem Zeitraum bereits geplant")
        break
      end
    end
  end
  
  def monday
    monday_am && monday_pm
  end
  
  def tuesday
    tuesday_am && tuesday_pm
  end
  
  def wednesday
    wednesday_am && wednesday_pm
  end
  
  def thursday
    thursday_am && thursday_pm
  end
  
  def friday
    friday_am && friday_pm
  end
  
  def percent
    result = 0
    result += 10 if monday_am
    result += 10 if monday_pm
    result += 10 if tuesday_am
    result += 10 if tuesday_pm
    result += 10 if wednesday_am
    result += 10 if wednesday_pm
    result += 10 if thursday_am
    result += 10 if thursday_pm
    result += 10 if friday_am
    result += 10 if friday_pm
    result
  end

private
  def overlaps?(existing_planning)
    if existing_planning != self
      #return true #todo: implement overlaps method
    end
  end
  
  def valid_week?(week)
    Week::valid?(week)
  end
end