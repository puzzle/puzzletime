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
  extend Manageable

  has_many :projects, -> { where(parent_id: nil) }

  has_many :all_projects, class_name: 'Project'
  has_many :worktimes, through: :all_projects

  before_destroy :protect_worktimes

  def to_s
    name
  end

  ##### interface methods for Manageable #####

  def self.labels
    ['Der', 'Geschäftsbereich', 'Geschäftsbereiche']
  end

  def self.puzzlebase_map
    Puzzlebase::Unit
  end

  ##### interface methods for Evaluatable #####

  def self.method_missing(symbol, *args)
    case symbol
      when :sum_worktime, :count_worktimes, :find_worktimes then Worktime.send(symbol, *args)
      else super
      end
  end

end
