# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class Client < ActiveRecord::Base

  include Evaluatable
  extend Manageable

  # All dependencies between the models are listed below.
  has_many :projects, :order => "name", :conditions => ['parent_id IS NULL']
  has_many :worktimes, :through => :projects
  
  # Validation helpers.
  validates_presence_of :name, :message => "Ein Name muss angegeben sein"
  validates_uniqueness_of :name, :message => "Dieser Name wird bereits verwendet"
  validates_presence_of :shortname, :message => "Ein Kürzel muss angegeben werden" 
  validates_uniqueness_of :shortname, :message => "Dieses Kürzel wird bereits verwendet" 
  
  before_destroy :protect_worktimes

  ##### interface methods for Manageable #####  
    
  def self.labels
    ['Der', 'Kunde', 'Kunden']
  end  
      
  def self.puzzlebaseMap
    Puzzlebase::Customer
  end      

  ##### interface methods for Evaluatable #####

  def self.method_missing(symbol, *args)
    case symbol
      when :sumWorktime, :countWorktimes, :findWorktimes : Worktime.send(symbol, *args) 
      else super
      end
  end
end
