class Puzzlebase::Customer < Puzzlebase::Base 
  has_many :customer_projects, 
           :foreign_key => 'FK_CUSTOMER'.downcase          
  has_many :projects, 
           :through => :customer_projects,
           :foreign_key => 'FK_CUSTOMER'.downcase,
           :conditions => 'FK_PROJECT IS NULL'.downcase
           
  MAPS_TO = ::Client         
  MAPPINGS = {:shortname => :S_CUSTOMER.to_s.downcase.to_sym,
              :name      => :S_DESCRIPTION.to_s.downcase.to_sym }
  FIND_OPTIONS = {:select => 'DISTINCT(TBL_CUSTOMER.*)'.downcase,
                  :joins => :customer_projects,
                  :conditions => ["TBL_CUSTOMER_PROJECT.B_SYNCTOPUZZLETIME = 't'".downcase]}
                  
end

class Client < ActiveRecord::Base    
  def debugString
    "#{shortname}: #{name}"
  end
end