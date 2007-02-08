# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class Projectmembership < ActiveRecord::Base

  belongs_to :employee
  belongs_to :project, :include => :client
  belongs_to :managed_project, 
             :class_name => 'Project', 
             :foreign_key => 'project_id',
             :include => :client, 
             :conditions => 'projectmemberships.projectmanagement IS TRUE'
  belongs_to :managed_employee, 
             :class_name => 'Employee',
             :foreign_key => 'employee_id' 
 
  validates_uniqueness_of :employee_id, 
                          :scope => 'project_id', 
                          :message => "Dieser Mitarbeiter ist bereits dem Projekt zugeteilt"
  validates_uniqueness_of :project_id, 
                          :scope => 'employee_id', 
                          :message => "Dieser Mitarbeiter ist bereits dem Projekt zugeteilt"

end
