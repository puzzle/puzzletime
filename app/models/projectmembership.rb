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

  def self.activate(attributes)
    membership = create(attributes) 
    membership = find(:first, assoc_conditions(attributes[:employee_id], attributes[:project_id]) )
    membership.update_attributes :active => true
  end
  
  def self.deactivate(id)
    membership = find(id)
    if membership.worktimes?
      membership.update_attributes :active => false 
    else  
      membership.destroy
    end
  end

  def worktimes?
    Worktime.count(self.class.assoc_conditions(employee_id, project_id)) > 0
  end
  
private  
  
  def self.assoc_conditions(employee_id, project_id)
    { :conditions => ['employee_id = ? AND project_id = ?', employee_id, project_id] }
  end
  
  
end
