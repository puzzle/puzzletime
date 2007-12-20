class ProjectEmployeesEval < Evaluation

  include Conditioner

  DIVISION_METHOD  = :employees
  LABEL            = 'Mitarbeiter'
  CATEGORY_REF     = 'ANY ( path_ids )'      
  
  def initialize(project_id)
    super(Project.find(project_id))
  end  
  
  def division_supplement(user)
    [[:last_completion, 'Komplettiert']]
  end
  
  def employee_id
     division.id if division
  end
 
  def account_id
   category.id
  end
 
  ####### overwritten methods for working with project hierarchies
 
  def category_label
    "Projekt: #{category.top? ? category.label : category.label_verbose}"
  end  
 
   def sendTimeQuery(method, period = nil, div = nil, options = {})
    options[:include] = :project
    super method, period, div, options
  end  
  
  def set_division_id(division_id = nil)
    return if division_id.nil?
    @division = Employee.find(division_id.to_i)
  end
  
end
