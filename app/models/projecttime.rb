class Projecttime < Worktime

  attr_reader :attendance
  
  validate :project_leaf  
  validate_on_update :protect_booked
  before_destroy :protect_booked
  before_destroy :protect_frozen
 
  def self.validAttributes
    super + [:account, :account_id, :description, :billable, :booked, :attendance]
  end    
  
  def self.account_label
    'Projekt'
  end
  
  def self.label
    'Projektzeit'
  end

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
    self.project_id = id
    self.project_id = DEFAULT_PROJECT_ID if project.nil?  # if id is nil or invalid, project is nil
    self.report_type = project.report_type if report_type < project.report_type
    self.billable = project.billable
  end
  
  def template(newWorktime = nil)
    newWorktime = super newWorktime    
    newWorktime.attendance = attendance if newWorktime.class == self.class
    newWorktime
  end
  
  def corresponding_type
    Attendancetime
  end
  
  ########### validation helpers ###########
  
  def validate
    super    
    project.validate_worktime self
  end
  
  def project_leaf
    errors.add(:project_id, "Das angegebene Projekt enthält Subprojekte.") if project(true).children?
  end
  
  def protect_booked
    previous = Projecttime.find(self.id)
    if previous.booked && self.booked
      errors.add_to_base "Verbuchte Arbeitszeiten k&ouml;nnen nicht ver&auml;ndert werden" 
      return false
    end
  end
  
  def protect_frozen
    project.validate_worktime_frozen(self)
  end
  
end