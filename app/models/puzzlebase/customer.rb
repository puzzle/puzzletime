class Puzzlebase::Customer < Puzzlebase::Base 
  has_many :customer_projects, 
           :foreign_key => 'FK_CUSTOMER'          
  has_many :projects, 
           :through => :customer_projects,
           :foreign_key => 'FK_CUSTOMER'
           
  MAPS_TO = ::Client         
  MAPPINGS = {:shortname => :S_CUSTOMER,
              :name      => :S_DESCRIPTION }
end

class Client < ActiveRecord::Base    
  def debugString
    "#{shortname}: #{name}"
  end
end