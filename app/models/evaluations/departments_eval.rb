# encoding: utf-8

class DepartmentsEval < Evaluation

  SUB_EVALUATION   = 'departmentprojects'
  LABEL            = 'Geschäftsbereiche'
  TOTAL_DETAILS    = false

  def initialize
    super(Department)
  end

end
