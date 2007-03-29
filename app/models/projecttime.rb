class Projecttime < Worktime
  def account
    project
  end
  
  def account_id
    project_id
  end
  
  def account_id=(value)
    self.project_id = value
  end
  
  def setProjectDefaults(id = nil)
    id ||= DEFAULT_PROJECT_ID 
    self.project_id = id
    self.report_type = project.report_type if report_type < project.report_type
    self.billable = project.billable
  end
  
  def self.account_label
    'Projekt'
  end
end