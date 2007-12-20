class Puzzlebase::Unit < Puzzlebase::Base        
  has_many :projects, 
           :foreign_key => 'FK_UNIT'.downcase
           
  MAPS_TO = ::Department         
  MAPPINGS = {:shortname => :S_UNIT.to_s.downcase.to_sym,
              :name      => :S_DESCRIPTION.to_s.downcase.to_sym }

end