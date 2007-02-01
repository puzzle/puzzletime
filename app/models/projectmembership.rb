# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class Projectmembership < ActiveRecord::Base

  # All dependencies between the models are listed below
  belongs_to :employee
  belongs_to :project
  belongs_to :managed_project, :class_name => 'Project', :include => :client, :conditions => 'projectmemberships.projectmanagement IS TRUE'
  belongs_to :managed_employee, :class_name => 'Employee'
 
  validates_uniqueness_of :employee_id, :scope => 'project_id', :message => "Dieser Mitarbeiter ist bereits dem Projekt zugeteilt"
  validates_uniqueness_of :project_id, :scope => 'employee_id', :message => "Dieser Mitarbeiter ist bereits dem Projekt zugeteilt"

end
