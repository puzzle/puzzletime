class Department < ActiveRecord::Base

  include Evaluatable
  extend Manageable
  
  has_many :projects, 
           :include => 'client',
           :order => 'clients.shortname, projects.name', 
           :conditions => ['parent_id IS NULL']
  has_many :all_projects, :class_name => 'Project'
  has_many :worktimes, :through => :all_projects
  
  before_destroy :protect_worktimes
  
  
  ##### interface methods for Manageable #####  
    
  def self.labels
    ['Der', 'Gesch&auml;ftsbereich', 'Gesch&auml;ftsbereiche']
  end  
      
  def self.puzzlebaseMap
    Puzzlebase::Unit
  end      

  ##### interface methods for Evaluatable #####

  def self.method_missing(symbol, *args)
    case symbol
      when :sumWorktime, :countWorktimes, :findWorktimes : Worktime.send(symbol, *args) 
      else super
      end
  end
  
end