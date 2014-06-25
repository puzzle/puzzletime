# encoding: utf-8
# == Schema Information
#
# Table name: departments
#
#  id        :integer          not null, primary key
#  name      :string(255)      not null
#  shortname :string(3)        not null
#


class Department < ActiveRecord::Base

  include Evaluatable

  has_many :projects, -> { where(parent_id: nil) }

  has_many :all_projects, class_name: 'Project'

  protect_if :worktimes, 'Dieser Eintrag kann nicht gelöscht werden, da ihm noch Arbeitszeiten zugeordnet sind'
  protect_if :projects, 'Dieser Eintrag kann nicht gelöscht werden, da ihm noch Projekte zugeordnet sind'

  scope :list, -> { order('name') }

  def to_s
    name
  end

  def worktimes
    Worktime.joins(:project).
             where(projects: { department_id: id })
  end

  ##### interface methods for Evaluatable #####

  def self.worktimes
    Worktime.all
  end

end
