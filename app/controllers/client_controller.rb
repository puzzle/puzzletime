# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class ClientController < ApplicationController

  include ManageModule 
  
  # Checks if employee came from login or from direct url
  before_filter :authorize   

  def modelClass
    Client
  end
  
  def listActions
    [['Projekte', 'project', 'list', false ]]
  end

end
