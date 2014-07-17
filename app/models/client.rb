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

  validates :work_item, presence: true

  delegate :name, :shortname, to: :work_item, allow_nil: true

  ##### interface methods for Evaluatable #####

  def self.worktimes
    Worktime.all
  end

  # TODO replace with above has_many_through_work_item
  def worktimes
    Worktime.joins(:project).
             where(projects: { client_id: id })
  end


end
