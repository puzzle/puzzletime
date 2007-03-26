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
  
  validates_presence_of :name, :message => "Ein Name muss angegeben sein"
  validates_uniqueness_of :name, :scope => 'client_id', :message => "Dieser Name wird bereits verwendet"
    
  before_destroy :protect_worktimes
  
  ##### interface methods for Manageable #####  
    
  def self.labels
    ['Das', 'Projekt', 'Projekte']
  end  
    
  def self.list(options = {})
    options[:include] ||= :client
    options[:order] ||= 'clients.name, projects.name'
    super(options)
  end
    
  def label_verbose
    client.name + ' - ' + name
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
