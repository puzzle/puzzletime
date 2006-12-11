
class Evaluation 

  attr_reader :category_class,        # Client, Project, Employee
              :category_method,       # gets list of categories from category_class
              :division_method,       # gets list of divisions from category
              :single_category,       # use this category instead of getting a list
              :label,                 # name of the evaluation, defaults to '#category #division'
              :receiver,              # receiver of category_methods, defaults to category_class
              :detail_category,       # category for detail view
              :detail_division        # division for detail view, can be nil
  
  def self.clients
    new(Client, :list, :projects) 
  end
  
  def self.managed(user)
    new(Project, :managed_projects, :employees, nil, 'Managed Projects', user)
  end
  
  def self.employees
    new(Employee, :list, :projects)
  end
  
  def self.absences
    new(Employee, :list, :absences)
  end
  
  def self.user(user)
    new(Employee, nil, :projects, user)
  end
  
  def self.userAbsences(user)
    new(Employee, nil, :absences, user)
  end
    
  def categories
    if single_category.nil?
      receiver.send(category_method)
    else
      single_category.to_a
    end  
  end
  
  def divisions(category)  
    category.send(division_method)
  end
      
  def absences?
    division_method == :absences
  end
  
  def details?
    ! detail_category.nil?
  end
  
  def division_details?
    ! detail_division.nil?
  end
  
  def times(period)
    if details?
      if division_details?
        detail_division.worktimesBy(period, absences?, detail_category.subdivisionRef)
      else
        detail_category.worktimesBy(period, absences?) 
      end 
    end 
  end
  
  def category_label
    detail_label(detail_category)
  end  
  
  def division_label
    detail_label(detail_division)
  end 
    
  def for?(user)
    single_category == user
  end
  
  def set_detail_ids(category_id, division_id = nil)
    self.detail_category = category_id
    if ! division_id.nil?
      @detail_division = divisions(detail_category).find(division_id.to_i)
    end
  end
    
private

  def initialize(clazz, category_method, division_method, category = nil, label = nil, receiver = nil)
    @category_class = clazz
    @category_method = category_method
    @division_method = division_method
    @single_category = category
    self.label = label
    self.receiver = receiver
  end
     
  def label=(label)
    @label = label || category_class.to_s + ' ' + division_method.to_s.capitalize  
  end     
       
  def receiver=(receiver)
    @receiver = receiver || category_class
  end     
    
  def detail_category=(id)
    @detail_category = single_category.nil? ? category_class.find(id.to_i) : single_category 
  end
     
  def detail_label(item)
    if ! item.nil?
      item.class.name + ': ' + item.label
    end  
  end   
end 