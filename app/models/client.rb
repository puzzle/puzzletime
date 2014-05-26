# encoding: utf-8
# == Schema Information
#
# Table name: clients
#
#  id        :integer          not null, primary key
#  name      :string(255)      not null
#  shortname :string(4)        not null
#


# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class Client < ActiveRecord::Base

  include Evaluatable
  extend Manageable

  # All dependencies between the models are listed below.
  has_many :projects, -> { where(parent_id: nil) }
  has_many :all_projects, class_name: 'Project'

  # Validation helpers.
  validates_presence_of :name, message: 'Ein Name muss angegeben sein'
  validates_uniqueness_of :name, message: 'Dieser Name wird bereits verwendet'
  validates_presence_of :shortname, message: 'Ein Kürzel muss angegeben werden'
  validates_uniqueness_of :shortname, message: 'Dieses Kürzel wird bereits verwendet'

  before_destroy :protect_worktimes

  scope :list, -> { order('name') }

  def to_s
    name
  end

  ##### interface methods for Manageable #####

  def self.puzzlebase_map
    Puzzlebase::CustomerProject
  end

  ##### interface methods for Evaluatable #####

  def self.method_missing(symbol, *args)
    case symbol
      when :sum_worktime, :count_worktimes, :find_worktimes then Worktime.send(symbol, *args)
      else super
      end
  end

  def worktimes
    Worktime.joins(:project).
             where(projects: { client_id: id })
  end
end
