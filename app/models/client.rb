# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class Client < ActiveRecord::Base

  include Evaluatable

  # All dependencies between the models are listed below.
  has_many :projects, :order => "name"
  has_many :worktimes, :through => :projects
  
  # Validation helpers.
  validates_presence_of :name, :message => "Ein Name muss angegeben sein"
  validates_uniqueness_of :name, :message => "Dieser Name wird bereits verwendet"
  
  before_destroy :protect_worktimes
  
       
  def self.list 
    find(:all, :order => "name")  
  end  
    
  def self.label
    'Kunde'
  end  
  
  def partnerId
    :client_id
  end
  
  def worktimesBy(period, absences = nil, dummy = nil, options = {})
    super(period, absences, id, options)
  end  

  def countWorktimes(period, absences = nil, dummy = nil)
    super(period, absences, id)
  end  
end
