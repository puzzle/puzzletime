# encoding: utf-8

# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class DepartmentController < ManageController

  GROUP_KEY = 'dept'

  def list_actions
    [['Projekte', 'project', 'list', true]]
  end

  def list_fields
    [[:name, 'Name'], [:shortname, 'Kürzel']]
  end

end
