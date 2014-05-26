# encoding: utf-8
# == Schema Information
#
# Table name: absences
#
#  id      :integer          not null, primary key
#  name    :string(255)      not null
#  payed   :boolean          default(FALSE)
#  private :boolean          default(FALSE)
#


# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class Absence < ActiveRecord::Base

  include Evaluatable
  extend Manageable

  # All dependencies between the models are listed below
  has_many :worktimes
  has_many :employees, through: :worktimes

  before_destroy :dont_destroy_vacation
  before_destroy :protect_worktimes


  # Validation helpers
  validates_presence_of :name, message: 'Eine Bezeichnung muss angegeben werden'
  validates_uniqueness_of :name, message: 'Diese Bezeichnung wird bereits verwendet'

  scope :list, -> { order(:name) }

  ##### interface methods for Manageable #####

  def dont_destroy_vacation
    fail 'Die Ferien Absenz kann nicht gelöscht werden' if id == VACATION_ID
  end

  def to_s
    name
  end

end
