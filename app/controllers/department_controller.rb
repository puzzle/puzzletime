# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class DepartmentController < ManageController

  def modelClass
    Department
  end
  
  def listActions
    [['Projekte', 'project', 'list', true ]]
  end
  
  def listFields
    [[:name, 'Name'], [:shortname, 'K&uuml;rzel']]
  end

end
