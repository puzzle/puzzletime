# encoding: utf-8

class DepartmentsEval < Evaluation

  self.sub_evaluation   = 'departmentprojects'
  self.label            = 'Geschäftsbereiche'
  self.total_details    = false

  def initialize
    super(Department)
  end

end
