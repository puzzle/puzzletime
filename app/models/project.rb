# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class Project < ActiveRecord::Base
  
  include Evaluatable
  extend Manageable
  include ReportType::Accessors

  # All dependencies between the models are listed below.
  has_many :projectmemberships, :dependent => :destroy, :finder_sql => 
    'SELECT m.* FROM projectmemberships m, employees e ' +
    'WHERE m.project_id = #{id} AND e.id = m.employee_id ' +
    'ORDER BY e.lastname, e.firstname'
  has_many :employees, :through => :projectmemberships, :order => "lastname, firstname"
  belongs_to :client
  has_many :worktimes
  
  validates_presence_of :name, :message => "Ein Name muss angegeben werden"  
  validates_uniqueness_of :name, :scope => 'client_id', :message => "Dieser Name wird bereits verwendet"
  validates_presence_of :shortname, :message => "Ein Kürzel muss angegeben werden" 
  validates_uniqueness_of :shortname, :scope => 'client_id', :message => "Dieses Kürzel wird bereits verwendet"
  validates_presence_of :client_id, :message => "Das Projekt muss einem Kunden zugeordnet sein"
    
  before_destroy :protect_worktimes
  
  ##### interface methods for Manageable #####  
    
  def self.labels
    ['Das', 'Projekt', 'Projekte']
  end  
    
  def self.list(options = {})
    options[:include] ||= :client
    options[:order] ||= 'clients.shortname, projects.name'
    super(options)
  end
        
  def self.puzzlebaseMap
    Puzzlebase::CustomerProject
  end      
    
  def label_verbose
    client.shortname + ' - ' + name
  end  
     
  def validate_worktime(worktime)
    if worktime.report_type < report_type
      worktime.errors.add(:report_type, 
        "Der Reporttyp muss eine Genauigkeit von mindestens #{report_type.name} haben") 
    end
    if description_required? && worktime.description.strip.empty?
      worktime.errors.add(:description, "Es muss eine Beschreibung angegeben werden")   
    end  
  end  

end
