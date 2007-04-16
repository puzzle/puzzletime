# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class ClientController < ManageController

  def modelClass
    Client
  end
  
  def listActions
    [['Projekte', 'project', 'list', false ]]
  end
  
  def listFields
    [[:shortname, 'K&uuml;rzel'], [:name, 'Name'], [:contact, 'Kontakt']]
  end

end
