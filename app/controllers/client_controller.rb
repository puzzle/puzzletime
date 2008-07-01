# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class ClientController < ManageController

  GROUP_KEY = 'client'
  
  
  def listActions
    [['Projekte', 'project', 'list', true ]]
  end
  
  def listFields
    [[:name, 'Name'], [:shortname, 'K&uuml;rzel']]
  end

end
