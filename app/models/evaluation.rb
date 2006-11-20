
class Evaluation 

  attr_reader :category_class, 
              :category_method, 
              :division_method, 
              :single_category, 
              :label, 
              :receiver
  
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
    if single_category == nil
      receiver.send(category_method)
    else
      single_category.to_a
    end  
  end
  
  def divisions(category)  
    category.send(division_method)
  end
    
  def category(id)
    if single_category == nil    
      category_class.find(id)
    else
      single_category.id == id ? single_category : nil
    end  
  end  
  
  def division(category, id)
    self.divisions(category).find(id)
  end
  
  def for?(user)
    single_category == user
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
    @label = label != nil ? label : category_class.to_s + ' ' + division_method.to_s.capitalize  
  end     
       
  def receiver=(receiver)
    @receiver = receiver != nil ? receiver : category_class
  end    
end 