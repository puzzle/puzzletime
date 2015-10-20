# encoding: utf-8

# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class DepartmentsController < ManageController
  self.permitted_attrs = :name, :shortname
end
