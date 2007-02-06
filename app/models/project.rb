# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class Project < ActiveRecord::Base
  
  include Evaluatable
  extend Manageable

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
  
  ##### interface methods for Manageable #####  
    
  def self.labels
    ['Das', 'Projekt', 'Projekte']
  end  
  
  def self.fieldNames    
    [[:name, 'Name'], 
     [:client_id, 'Kunde'],
     [:description, 'Beschreibung']]    
  end
  
  def self.listFields
    [[:name, 'Name'], 
     [:client, 'Kunde']]
  end
    
  def self.list(options = {})
    options[:include] ||= :client
    options[:order] ||= 'clients.name, projects.name'
    super(options)
  end
    
  def self.label
    'Projekt'
  end
      
  def label_verbose
    client.name + ' - ' + name
  end    

end
