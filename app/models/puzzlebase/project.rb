class Puzzlebase::Project < Puzzlebase::Base  
  has_many :customer_projects, 
           :foreign_key => 'FK_PROJECT'.downcase, 
           :class_name => 'Puzzlebase::CustomerProject'
  has_many :customers,
           :through => :customer_projects,
           :foreign_key => 'FK_PROJECT'.downcase
  has_many :children,
           :class_name => 'Puzzlebase::Project',
           :foreign_key => 'FK_PROJECT'.downcase
  belongs_to :unit,
             :foreign_key => 'FK_UNIT'.downcase
           
  MAPS_TO = ::Project         
  MAPPINGS = {:shortname => :S_PROJECT.to_s.downcase.to_sym,
              :name      => :S_DESCRIPTION.to_s.downcase.to_sym}  
  FIND_OPTIONS = {:select => 'DISTINCT(TBL_PROJECT.*)'.downcase,
                  :joins => :customer_projects,
                  :conditions => ["TBL_CUSTOMER_PROJECT.B_SYNCTOPUZZLETIME = 't' AND TBL_PROJECT.FK_PROJECT is null".downcase]}    
       
  def self.updateChildren(original, local_parent)
    original.children.each do |child|
      local = self::MAPS_TO.find(:first, :conditions => ["shortname = ? AND parent_id = ?", child.s_project, local_parent.id])
      local = self::MAPS_TO.new if local.nil?
      updateAttributes local, child
      local.parent_id = local_parent.id
      local.client_id = local_parent.client_id
      success = saveUpdated local
      updateChildren child, local if success
    end
  end
  
protected
           
  def self.updateLocal(original)
    locals = ::Project.find_all_by_shortname(original.S_PROJECT)
    locals.each do |local|
      updateAttributes local, original
      success = saveUpdated local
      updateChildren original, local if success
    end
  end 
 
end


class Project < ActiveRecord::Base
  def debugString
    "#{shortname}: #{name}"
  end
end