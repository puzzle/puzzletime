module Puzzlebase
  class Base < ActiveRecord::Base
    # Set up database connection to puzzlebase for all subclasses of Base
    establish_connection :puzzlebase
    
    # Set database properties
    set_table_name(nil) { "TBL_#{self.table_id}" }
    set_primary_key(nil) { "PK_#{self.table_id}" }
    
    # The model class the Puzzlebase model maps to.
    MAPS_TO = nil
    # The attributes of the model class that map to the puzzlebase attributes.
    MAPPINGS = {}
    
    # Synchronizes Clients, Projects, Employees and Employments from puzzlebase    
    def self.synchronizeAll
      resetErrors
      Puzzlebase::Customer.updateAll
      Puzzlebase::CustomerProject.updateAll
      Puzzlebase::Employee.updateAll
      Puzzlebase::Employment.updateAll
      errors
    end
    
    # Synchronizes the entries for this puzzlebase table.
    def self.synchronize
      resetErrors
      updateAll
      errors
    end 
    
  protected  
  
    # Updates all entries of the receiver from puzzlebase
    def self.updateAll
      find(:all).each { |original| updateLocal original }
    end
      
    # Updates or creates a corresponding local entry from an original entry
    # in puzzlebase and saves it.
    def self.updateLocal(original)
      local = self::MAPS_TO.find(:first, localFindOptions(original))
      local = self::MAPS_TO.new if local.nil?
      updateAttributes local, original
      setReference local, original
      saveUpdated local
    end 
    
    # Updates all attributes of the local entry from the original entry in puzzlebase.
    # based on the MAPPINGS defined.
    def self.updateAttributes(local, original)
      self::MAPPINGS.each_pair do |localAttr, originalAttr| 
        local.send :"#{localAttr}=", original.send(originalAttr)
      end 
    end
    
    # Saves an update local entry and logs potential error messages.
    def self.saveUpdated(local)
      unless local.save
        errors.push local
      end
    end
    
    # SQL select conditions for entries with references to other tables,
    # called by updateLocalWithReference.
    def self.localFindOptions(original)     
       {:conditions => ["shortname = ?", original.send(self::MAPPINGS[:shortname])]} 
    end     
    
    # Sets the local reference based on the original entry from puzzlebase,
    # called by updateLocalWithReference.
    def self.setReference(local, original)
    end
    
    # Helper method to compute the table name in puzzlebase 
    def self.table_id
      name.demodulize.upcase
    end   
    
    # Returns an Array of errorenous entries resulting from a synchronization process.
    def self.errors
      @@errors
    end
    
    # Resets all errorenous entries.
    def self.resetErrors
      @@errors = Array.new
    end    
    
  end
end