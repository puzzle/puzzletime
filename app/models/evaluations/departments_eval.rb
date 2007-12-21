class DepartmentsEval < Evaluation

  SUB_EVALUATION   = 'departmentprojects'
  LABEL            = 'Gesch&auml;ftsbereiche'
  TOTAL_DETAILS    = false    
  
  def initialize
    super(Department)
  end
  
end