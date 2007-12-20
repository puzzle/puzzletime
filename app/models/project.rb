# (c) Puzzle itc, Berne:projects
# Diplomarbeit 2149, Xavier Hayoz

class Project < ActiveRecord::Base
 
  # topfunky hack to get sums for the worktimes association
  module WorktimeAssoc
    include Conditioner
 
    def sum(column_name, options = {})
      options = restrict_conditions options
      @reflection.klass.sum(column_name, options)
    end
    
    def find(*args)
      case args.first
        when :first, :all then 
          options = restrict_conditions args.extract_options!
          @reflection.klass.find(args.first, options)
        else 
          @reflection.klass.find(args)
      end
    end
    
    def restrict_conditions(options)
      options = clone_options options
      append_conditions(options[:conditions], 
                        [ "worktimes.project_id = projects.id AND #{@owner.id} = ANY (projects.path_ids)" ])
      options[:include] = 'project'
      options
    end
  end
  
  include Evaluatable
  extend Manageable
  include ReportType::Accessors

  # All dependencies between the models are listed below.
  has_many :projectmemberships, :dependent => :destroy,
           :include => :employee,
           :order => 'employees.lastname, employees.firstname'
  #defined in custom method         
  #has_many :employees, :through => :worktimes, :uniq => true, :order => "lastname, firstname"
  
  has_many :children, :class_name => 'Project', :foreign_key => 'parent_id', :order => 'name'
  belongs_to :parent, :class_name => 'Project', :foreign_key => 'parent_id'
  belongs_to :department
  belongs_to :client
  
  has_many :worktimes, :extend => Project::WorktimeAssoc
  
  validates_presence_of :name, :message => "Ein Name muss angegeben werden"  
  validates_uniqueness_of :name, :scope => 'parent_id', :message => "Dieser Name wird bereits verwendet"
  validates_presence_of :shortname, :if => Proc.new {|p| p.parent_id.nil? }, :message => "Ein Kürzel muss angegeben werden" 
  validates_uniqueness_of :shortname, :scope => 'parent_id', :message => "Dieses Kürzel wird bereits verwendet"
  validates_presence_of :client_id, :message => "Das Projekt muss einem Kunden zugeordnet sein"
    
  before_destroy :protect_worktimes
  before_save :generate_path_ids
  
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
