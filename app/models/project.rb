# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class Project < ActiveRecord::Base
  
  include Evaluatable

  # All dependencies between the models are listed below.
  has_many :projectmemberships, :dependent => true, :finder_sql => 
    'SELECT m.* FROM projectmemberships m, employees e ' +
    'WHERE m.project_id = #{id} AND e.id = m.employee_id ' +
    'ORDER BY e.lastname, e.firstname'
  has_many :employees, :through => :projectmemberships, :order => "lastname, firstname"
  belongs_to :client
  has_many :worktimes, :dependent => true
  
  validates_presence_of :name, :message => "Ein Name muss angegeben sein"
  validates_uniqueness_of :name, :message => "Dieser Name wird bereits verwendet"
    
  before_destroy :protect_worktimes
  
  
  def self.list(options = {})
    options.merge!({:include => :client,
                    :order => 'clients.name, projects.name'})
    self.find(:all, options)
  end
    
  def self.label
    'Projekt'
  end
      
  def label_verbose
    client.name + ' - ' + name
  end  
  

end
