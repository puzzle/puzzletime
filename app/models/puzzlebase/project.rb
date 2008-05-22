class Puzzlebase::Project < Puzzlebase::Base  
  has_many :customer_projects, 
           :foreign_key => 'FK_PROJECT', 
           :class_name => 'Puzzlebase::CustomerProject'
  has_many :customers,
           :through => :customer_projects,
           :foreign_key => 'FK_PROJECT'
  has_many :children,
           :class_name => 'Puzzlebase::Project',
           :foreign_key => 'FK_PROJECT'
  belongs_to :unit,
             :foreign_key => 'FK_UNIT'
           
  MAPS_TO = ::Project         
  MAPPINGS = {:shortname      => :S_PROJECT,
              :name           => :S_DESCRIPTION}  
  FIND_OPTIONS = {:select => 'DISTINCT(TBL_PROJECT.*)',
                  :joins => :customer_projects,
                  :conditions => ["TBL_CUSTOMER_PROJECT.B_SYNCTOPUZZLETIME = 't' AND TBL_PROJECT.FK_PROJECT is null"]}    
       
       
  def self.updateChildren(original_parent, local_parent)
    original_children = original_parent.children
    return if original_children.empty?
    moveWorktimesIfNecessary(original_parent, local_parent, original_children)
    
    original_children.each do |child|
      local = findLocalChild(child, local_parent)
      local = updateLocalChild local_parent, child, local
      updateChildren child, local if local
    end
  end
  
  def self.removeUnused
    removeUnusedExcept findAll, 'parent_id IS NULL'
    top_projects = Project.find(:all, :conditions => ['parent_id IS NULL'])
    top_projects.each do |local|
      removeUnusedChildren findOriginal(local), local
    end
  end
  
protected
           
  def self.updateLocal(original)
    locals = ::Project.find_all_by_shortname(original.S_PROJECT)
    locals.each do |local|
      updateAttributes local, original
      setReference local, original
      success = saveUpdated local
      updateChildren original, local if success
    end
  end
  
  def self.setReference(local, original)
    department = ::Department.find_by_shortname(original.unit.S_UNIT)
    local.department_id = department.id if department
  end
  
  def self.updateLocalChild(local_parent, original, local = nil)
    local ||= self::MAPS_TO.new
    updateAttributes local, original
    setReference local, original
    local.parent_id = local_parent.id
    local.client_id = local_parent.client_id
    success = saveUpdated local
    success ? local : false
  end
  
  def self.findLocalChild(original_child, local_parent)
    self::MAPS_TO.find(:first, :conditions => ["shortname = ? AND parent_id = ?", original_child.S_PROJECT, local_parent.id])
  end
    
  def self.findOriginal(local)
    find(:first, :conditions => ['FK_PROJECT IS NULL AND S_PROJECT = ?', local.shortname])
  end

  def self.moveWorktimesIfNecessary(original_parent, local_parent, original_children)
    existing_children = original_children.select { |child| not findLocalChild(child, local_parent).nil? }
    if existing_children.empty? && ! local_parent.worktimes.empty?
      originals = original_children.select { |original| original.S_PROJECT == local_parent.shortname }
      child = updateLocalChild local_parent, 
                               originals.empty? ? original_parent : originals.first
      local_parent.move_times_to child
    end
  end
    
  def self.removeUnusedChildren(original_parent, local_parent)
    original_children = original_parent.children
    removeUnusedExcept original_children, "parent_id = #{local_parent.id}"
    original_children.each do |child|
      removeUnusedChildren child, findLocalChild(child, local_parent)
    end
  end
  
end


class Project < ActiveRecord::Base
  def debugString
    "#{shortname}: #{name}"
  end
end