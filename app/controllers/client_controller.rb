# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class ClientController < ApplicationController

  include ManageModule 
  
  before_filter :authorize   

  def modelClass
    Client
  end
  
  def listActions
    [['Projekte', 'project', 'list', false ]]
  end
  
  def editFields
    [[:name, 'Name'], [:contact, 'Kontakt']]
  end

end
