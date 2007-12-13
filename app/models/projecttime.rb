class Projecttime < Worktime

  attr_reader :attendance

  def account
    project
  end
  
  def account_id
    project_id
  end
  
  def account_id=(value)
    self.project_id = value
  end
  
  def attendance=(value)
    @attendance = value.kind_of?(String) ? value.to_i != 0 : value
  end
  
  def setProjectDefaults(id = nil)
    id ||= DEFAULT_PROJECT_ID 
    self.project_id = id
    self.report_type = project.report_type if report_type < project.report_type
    self.billable = project.billable
  end
  
  def self.validAttributes
    super + [:account, :account_id, :description, :billable, :attendance]
  end   
      
  def validate
    super    
    project.validate_worktime self
  end
  
  def self.account_label
    'Projekt'
  end
  
  def self.label
    'Projektzeit'
  end
  
  def template(newWorktime = nil)
    newWorktime = super newWorktime    
    newWorktime.attendance = attendance if newWorktime.class == self.class
    newWorktime
  end
  
  def corresponding_type
    Attendancetime
  end
end