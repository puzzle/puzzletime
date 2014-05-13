# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class Absence < ActiveRecord::Base

  include Evaluatable
  extend Manageable

  # All dependencies between the models are listed below
  has_many :worktimes
  has_many :employees, through: :worktimes, order: 'lastname'

  before_destroy :dont_destroy_vacation
  before_destroy :protect_worktimes


  # Validation helpers
  validates_presence_of :name, message: 'Eine Bezeichnung muss angegeben werden'
  validates_uniqueness_of :name, message: 'Diese Bezeichnung wird bereits verwendet'

  ##### interface methods for Manageable #####

  def self.labels
    %w(Die Absenz Absenzen)
  end

  def dont_destroy_vacation
    fail 'Die Ferien Absenz kann nicht gel&ouml;scht werden' if id == VACATION_ID
  end

end
