# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class Absence < ActiveRecord::Base

  include Evaluatable
  
  # All dependencies between the models are listed below
  has_many :worktimes, :dependent => true
  has_many :employees, :through => :worktimes, :order => "lastname"

  before_destroy :dont_destroy_vacation
  before_destroy :protect_worktimes
  
  
  # Validation helpers
  validates_presence_of :name, :message => "Ein Name muss angegeben werden"
  validates_uniqueness_of :name, :message => "Dieser Name wird bereits verwendet"
    
  def self.list
    find(:all, :order => 'name')
  end
  
  def self.label
    'Absenz'
  end
  
  def dont_destroy_vacation
    raise "Die Ferien Absenz kann nicht gel&ouml;scht werden" if self.id == VACATION_ID
  end  
   
end
