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
           
  belongs_to :department
  belongs_to :client
  
  has_many :worktimes, :extend => HasTreeAssociation
  
  before_validation DateFormatter.new('freeze_until')
  
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
    path_labels = path_ids[0..-2].collect{ |id| self.class.find(id).shortname }
    path_label = "-#{path_labels.join("-")}" if not path_labels.empty?
    "#{client.shortname}#{path_label}: #{name}"
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
  
  def managed_employees
    Employee.find(:all, :select => 'DISTINCT(employees.*)',
    					:joins => { :projectmemberships => :project },
    					:conditions => ['projectmemberships.project_id IN (?) AND projectmemberships.active', path_ids],
    					:order => 'lastname, firstname' )
  end
  
  def employees
    Employee.find(:all, :select => 'DISTINCT(employees.*)',
                        :joins => { :worktimes => :project },
                        :conditions => ['? = ANY (projects.path_ids)', self.id],
                        :order => 'lastname, firstname')
  end
  
  def freeze_until
    # cache date to prevent endless string_to_date conversion
    @freeze_until ||= read_attribute(:freeze_until)
  end
  
  def freeze_until=(value)
    write_attribute(:freeze_until, value)
    @freeze_until = nil
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
    if description_required? && worktime.description.blank?
      worktime.errors.add(:description, "Es muss eine Beschreibung angegeben werden")   
    end  
    if freeze_until && worktime.work_date <= freeze_until
      worktime.errors.add(:work_date, 
        "Die Zeiten vor dem #{freeze_until.strftime(DATE_FORMAT)} wurden für dieses Projekt eingefroren und können nicht mehr geändert werden. Um diese Arbeitszeit trotzdem zu erfassen, wende dich bitte an den entsprechenden Projektleiter.")
    end
  end  
  
end
