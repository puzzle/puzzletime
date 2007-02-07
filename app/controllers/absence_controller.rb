# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class AbsenceController < ApplicationController

  include ManageModule

  # Checks if employee came from login or from direct url.
  before_filter :authorize
   
  def modelClass
    Absence
  end   
    
  def editFields
    [[:name, 'Bezeichnung'], [:payed, 'Bezahlt']]
  end 
  
end
