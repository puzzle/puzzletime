# encoding: utf-8

class DepartmentsController < ManageController
  self.permitted_attrs = :name, :shortname
end
