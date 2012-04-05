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

  def self.top_projects
    list.select{|c| c.top? }
  end
  
  def label_verbose
  	path_labels = ancestor_projects.collect(&:shortname) 
    path_label = "-#{path_labels.join("-")}" if not path_labels.empty?
    "#{client.shortname}#{path_label}: #{name}"
  end
    
  def ancestor_projects
    @ancestor_projects ||= begin
      ids = path_ids[0..-2]
      ps = Hash[self.class.find(ids).collect {|p| [p.id, p]}]
      ids.collect {|id| ps[id] }
    end
  end
  
  def label_ancestry
  	(ancestor_projects + [self]).collect(&:name).join(" - ")
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
  
  def ==(other)
    id == other.id? && !id.nil?
 	end
  
  def <=>(other)
    return super(other) if self.kind_of? Class
    
    "#{client.shortname}: #{label_ancestry}" <=> "#{other.client.shortname}: #{other.label_ancestry}"
  end
  
  
  def validate_worktime(worktime)
    if worktime.report_type < report_type
      worktime.errors.add(:report_type, 
        "Der Reporttyp muss eine Genauigkeit von mindestens #{report_type.name} haben") 
    end
    
    if worktime.report_type != AutoStartType::INSTANCE && description_required? && worktime.description.blank?
      worktime.errors.add(:description, "Es muss eine Beschreibung angegeben werden")   
    end  
    
    if worktime.report_type != AutoStartType::INSTANCE && ticket_required? && worktime.ticket.blank?
      worktime.errors.add(:ticket, "Es muss ein Ticket/Task angegeben werden")   
    end  
     
    validate_worktime_frozen(worktime)
  end  
  
  def validate_worktime_frozen(worktime)
    if freeze = latest_freeze_until
      if worktime.work_date <= freeze || (!worktime.new_record? && Worktime.find(worktime.id).work_date <= freeze)
        worktime.errors.add(:work_date, "Die Zeiten vor dem #{freeze.strftime(DATE_FORMAT)} wurden für dieses Projekt eingefroren und können nicht mehr geändert werden. Um diese Arbeitszeit trotzdem zu bearbeiten, wende dich bitte an den entsprechenden Projektleiter.")
        false
      end
    end
  end
  
  def latest_freeze_until
    if parent.nil?
      freeze_until
    else     
      parent_freeze_until = parent.latest_freeze_until
      if freeze_until.nil?
        parent_freeze_until
      elsif parent_freeze_until.nil?
        freeze_until
      else
        [freeze_until, parent_freeze_until].max
      end
    end
  end
  
end
