# encoding: utf-8

# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class ClientsController < ManageController

  self.permitted_attrs = :name, :shortname

end
