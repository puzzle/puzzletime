# encoding: utf-8
# == Schema Information
#
# Table name: clients
#
#  id           :integer          not null, primary key
#  name         :string(255)      not null
#  shortname    :string(4)        not null
#  work_item_id :integer
#

# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class Client < ActiveRecord::Base

  include BelongingToWorkItem
  include Evaluatable

  # must be before associations to prevent their destroy
  protect_if :worktimes, 'Dieser Eintrag kann nicht gelöscht werden, da ihm noch Arbeitszeiten zugeordnet sind'

  # All dependencies between the models are listed below.
  has_many :projects, -> { where(parent_id: nil) }
  has_many :all_projects, class_name: 'Project', dependent: :destroy
  has_many :contacts
  has_many :billing_addresses

  has_many_through_work_item :orders
  has_many_through_work_item :accounting_posts
  #has_many_through_work_item :worktimes

  # Validation helpers.
  validates_presence_of :name, message: 'Ein Name muss angegeben sein'
  validates_uniqueness_of :name, message: 'Dieser Name wird bereits verwendet'
  validates_presence_of :shortname, message: 'Ein Kürzel muss angegeben werden'
  validates_uniqueness_of :shortname, message: 'Dieses Kürzel wird bereits verwendet'

  before_save :remember_name_changes
  after_save :update_projects_path_names


  scope :list, -> { order('name') }

  def to_s
    name
  end

  ##### interface methods for Evaluatable #####

  def self.worktimes
    Worktime.all
  end

  # TODO replace with above has_many_through_work_item
  def worktimes
    Worktime.joins(:project).
             where(projects: { client_id: id })
  end

  private

  def remember_name_changes
    @names_changed = name_changed? || shortname_changed?
  end

  def update_projects_path_names
    if @names_changed
      projects.find_each do |p|
        p.update_path_names!
      end
      @names_changed = false
    end
  end
end
