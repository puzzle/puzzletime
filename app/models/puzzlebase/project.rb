module Puzzlebase
  class Project < Base  
    has_many :customer_projects, 
             :foreign_key => 'FK_PROJECT', 
             :class_name => 'Puzzlebase::CustomerProject'
    has_many :customers,
             :through => :customer_projects,
             :foreign_key => 'FK_PROJECT'
             
    MAPS_TO = ::Project         
    MAPPINGS = {:shortname => :S_PROJECT,
                :name      => :S_DESCRIPTION }  
                          
  protected
             
    def self.updateLocal(original)
      locals = ::Project.find_all_by_shortname(original.S_PROJECT)
      locals.each do |local|
        updateAttributes local, original
        saveUpdated local
      end
    end 
  end
end