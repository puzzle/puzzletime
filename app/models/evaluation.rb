
class Evaluation 

  attr_reader :category,              # category
              :sub_evaluation,        # next evaluation for divisions
              :division,              # selected division for details
              :division_method,       # gets list of divisions from category
              :label,                 # name of the evaluation, defaults to '#category #division'
              :absences,              # worktimes for projects or absences?
              :top_category,          # details for top_category totals not possible
              :category_times         # should divisions only contain worktimes from category

  
  def self.clients
    new(Client, :list, 'Clients', :clientProjects, false, true, false) 
  end
  
  def self.employees
    new(Employee, :list, 'Employee Projects', :employeeProjects, false, true, false)
  end
  
  def self.absences
    new(Employee, :list, 'Employee Absences', :employeeAbsences, true, true, false)
  end  
    
  def self.managedProjects(user)
    new(user, :managed_projects, 'Managed Projects', :projectEmployees, false, true, false)
  end
  
  def self.clientProjects(client_id)
    new(Client.find(client_id), :projects, 'Projects', :projectEmployees, false, false, false) 
  end
  
  def self.employeeProjects(employee_id)
    new(Employee.find(employee_id), :projects, 'Projects') 
  end
  
  def self.projectEmployees(project_id)
    new(Project.find(project_id), :employees, 'Employees') 
  end
  
  def self.employeeAbsences(employee_id)
    new(Employee.find(employee_id), :absences, 'Absences', nil, true)
  end
  
  ########  instance methods ########
  
  def divisions  
    @category.send(division_method)
  end
      
  def absences?
    @absences
  end
  
  def subdivision_ref
    @category_times ? @category.id : 0
  end

  def sum_times(period, div = nil)
    div = div || division
    if div then div.sumWorktime(period, @absences, subdivision_ref)
    else category.sumWorktime(period, @absences)
    end
  end  
  
  def count_times(period)
    if division then division.countWorktimes(period, @absences, subdivision_ref)
    else category.countWorktimes(period, @absences)
    end
  end
  
  def times(period, options = {})
    if division then division.worktimesBy(period, @absences, subdivision_ref, options)
    else category.worktimesBy(period, @absences, 0, options)
    end
  end
  
  def category_label
    if managed? then 'Client: ' + division.client.name
    else detail_label(category)
    end
  end  
  
  def division_label
    detail_label(division)
  end 
  
  def title
    if class_category?
      label + " Overview"
    else
      label + " of " + category.label
    end  
  end
  
  def division_header
    divs = divisions
    if divs.first
      divs.first.class.to_s.capitalize
    else
      ""
    end  
  end
    
  def for?(user)
    category == user && ! managed?
  end
  
  def set_division_id(division_id = nil)
    if division_id
      if class_category?
         @division = category.find(division_id.to_i)
      else   
         @division = divisions.find(division_id.to_i)
      end  
    end
  end
      
private

  def initialize(category, division_method, label = nil, sub_evaluation = nil, absences = false, top_category = false, category_times = true)
    @category = category
    @division_method = division_method
    @sub_evaluation = sub_evaluation
    @absences = absences
    @top_category = top_category
    @category_times = category_times
    self.label = label
  end
  
  def label=(label)
    @label = label || category.label 
  end     
       
  def detail_label(item)
    if ! ( item.nil? || item.kind_of?(Class) )
      item.class.name + ': ' + item.label
    end  
  end   
  
  def managed?
    division_method == :managed_projects
  end
  
  def class_category?
    category.kind_of? Class
  end
end 