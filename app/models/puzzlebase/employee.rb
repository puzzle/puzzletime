module Puzzlebase 
  class Employee < Base  
    has_many :employments,
             :foreign_key => 'FK_EMPLOYEE'
    
    MAPS_TO = ::Employee         
    MAPPINGS = {:shortname => :S_SHORTNAME,
                :lastname  => :S_LASTNAME,
                :firstname => :S_FIRSTNAME,
                :ldapname  => :S_LDAPNAME,
                :email     => :S_EMAIL }    
  end  
  
  # Synchronizes the Employees and their Employments.
  def self.synchronize
    resetErrors
    updateAll
    Puzzlebase::Employement.updateAll
    errors
  end 
end