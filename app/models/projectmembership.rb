# encoding: utf-8
# == Schema Information
#
# Table name: projectmemberships
#
#  id                :integer          not null, primary key
#  project_id        :integer          not null
#  employee_id       :integer          not null
#  projectmanagement :boolean          default(FALSE), not null
#  active            :boolean          default(TRUE), not null
#

# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class Projectmembership < ActiveRecord::Base

  belongs_to :employee
  belongs_to :project
  belongs_to :managed_project,
             -> { where(projectmemberships: { projectmanagement: true }) },
             class_name: 'Project',
             foreign_key: 'project_id'
  belongs_to :managed_employee,
             class_name: 'Employee',
             foreign_key: 'employee_id'

  validates_presence_of :employee_id, message: 'Es muss ein Mitarbeiter angegeben werden'
  validates_presence_of :project_id, message: 'Es muss ein Projekt angegeben werden'

  validates_uniqueness_of :employee_id,
                          scope: 'project_id',
                          message: 'Dieser Mitarbeiter ist bereits dem Projekt zugeteilt'
  validates_uniqueness_of :project_id,
                          scope: 'employee_id',
                          message: 'Dieser Mitarbeiter ist bereits dem Projekt zugeteilt'

  scope :list, -> do
    includes(:project).
    references(:project).
    order('projects.path_shortnames')
  end


  def self.activate(attributes)
    create(attributes)
    membership = where(assoc_conditions(attributes[:employee_id], attributes[:project_id])[:conditions]).first
    membership.update_attributes active: true
  end

  def self.deactivate(id)
    membership = find(id)
    if membership.worktimes?
      membership.update_attributes active: false
    else
      membership.destroy
    end
  end

  def worktimes?
    Worktime.count(self.class.assoc_conditions(employee_id, project_id)) > 0
  end

  private

  def self.assoc_conditions(employee_id, project_id)
    { conditions: ['employee_id = ? AND project_id = ?', employee_id, project_id] }
  end


end
