# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class Absence < ActiveRecord::Base

  include Division
  
  # All dependencies between the models are listed below
  has_many :worktimes, :dependent => true
  has_many :employees, :through => :worktimes, :order => "lastname"

  before_destroy :dont_destroy_vacation
  
  # Validation helpers
  validates_presence_of :name
  validates_uniqueness_of :name
  
  VACATION_ID = 1     
  
  def self.list
    find(:all, :order => 'name')
  end
  
  def dont_destroy_vacation
    raise "Can't delete vacation absence" if self.id == VACATION_ID
  end  
   
end
