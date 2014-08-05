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
  belongs_to :work_item

  has_many :contacts
  has_many :billing_addresses

  has_descendants_through_work_item :orders
  has_descendants_through_work_item :accounting_posts

  validates :work_item, presence: true

  delegate :name, :shortname, to: :work_item, allow_nil: true

  ##### interface methods for Evaluatable #####

  def self.worktimes
    Worktime.all
  end

end
