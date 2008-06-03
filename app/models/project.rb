# (c) Puzzle itc, Berne:projects
# Diplomarbeit 2149, Xavier Hayoz

class Project < ActiveRecord::Base
 
  include Evaluatable
  extend Manageable
  include ReportType::Accessors

  acts_as_tree :order => 'name'

  # All dependencies between the models are listed below.
  has_many :projectmemberships, 
           :dependent => :destroy,
           :include => :employee,
           :order => 'employees.lastname, employees.firstname'
  #defined in custom method         
  #has_many :employees, :through => :worktimes, :uniq => true, :order => "lastname, firstname"
  
  has_many :managed_employees, 
           :class_name => 'Employee',
           :through => :projectmemberships, 
           :conditions => 'projectmemberships.active',
           :order => "lastname, firstname"
           
  belongs_to :department
  belongs_to :client
  
  has_many :worktimes, :extend => HasTreeAssociation
  
  validates_presence_of :name, :message => "Ein Name muss angegeben werden"  
  validates_uniqueness_of :name, :scope => [:parent_id, :client_id], :message => "Dieser Name wird bereits verwendet"
  validates_presence_of :shortname, :message => "Ein Kürzel muss angegeben werden" 
  validates_uniqueness_of :shortname, :scope => [:parent_id, :client_id], :message => "Dieses Kürzel wird bereits verwendet"
  validates_presence_of :client_id, :message => "Das Projekt muss einem Kunden zugeordnet sein"
  validates_presence_of :department_id, :message => "Das Projekt muss einem Gesch&auml;ftsbereich zugeordnet sein"
    
  before_destroy :protect_worktimes
  
  #yep, this triggers before_update to generate path_ids after the project got its id and saves it again
  after_create :save  
  before_update :generate_path_ids
  
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
    
  def self.columnType(col)
    case col 
      when :report_type : :report_type
      else super col
      end
  end  
  
  def self.leaves
    list.select {|project| project.leaf? }
  end
  
  def label_verbose
    "#{client.shortname} - #{top_project.shortname+': ' unless top?}#{name}"
  end  
  
  def label_ancestry
    top? ? name : "#{parent.label_ancestry} - #{name}"
  end
  
  def top_project
    self.class.find(path_ids[0])
  end
  
  def top?
    parent_id.nil?
  end
  
  def children?
    not children.empty?
  end
  
  def leaf?
    children.empty?
  end
  
  def leaves
    return [self] if leaf?
    children.collect{|p| p.leaves }.flatten
  end
  
  def path_ids=(ids)
    ids = [ids] unless ids.is_a? Array
    write_attribute(:path_ids, "{#{ids.join(',')}}")
  end

  def path_ids
    ids = read_attribute(:path_ids)
    return [] if ids.nil?
    ids[1..-2].split(/,\s*/).collect { |i| i.to_i }
  end
  
  def employees
    Employee.find(:all, :select => 'DISTINCT(employees.*)',
                        :joins => { :worktimes => :project },
                        :conditions => ['? = ANY (projects.path_ids)', self.id],
                        :order => 'lastname, firstname')
  end

  def move_times_to(other)
    Projecttime.update_all ["project_id = ?", other.id], ["project_id = ?", self.id]
  end

  def generate_path_ids
    self.path_ids = top? ? [id] : parent.path_ids.clone.push(id)
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
