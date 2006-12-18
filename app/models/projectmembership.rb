# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class Projectmembership < ActiveRecord::Base

  # All dependencies between the models are listed below
  belongs_to :employee
  belongs_to :project
  belongs_to :managed_project, :class_name => 'Project', :conditions => 'projectmemberships.projectmanagement IS TRUE'
 
  validates_uniqueness_of :employee_id, :scope => 'project_id'
  validates_uniqueness_of :project_id, :scope => 'employee_id'

end
