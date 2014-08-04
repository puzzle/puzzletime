# encoding: utf-8

class DepartmentsEval < Evaluation

  self.division_column   = 'projects.department_id'
  self.division_join     = :project
  self.sub_evaluation   = 'departmentprojects'
  self.label            = 'Geschäftsbereiche'
  self.total_details    = false

  def initialize
    super(Department)
  end

end
