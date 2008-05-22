# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class AbsenceController < ManageController
   
  def modelClass
    Absence
  end   
    
  def editFields
    [[:name, 'Bezeichnung'], [:payed, 'Bezahlt'], [:private, 'Nicht öffentlich']]
  end 
  
end
