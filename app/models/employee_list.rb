class EmployeeList < ActiveRecord::Base
  
  belongs_to :employee
  has_many :employee_list_items, 
           :dependent => :destroy
  
  validates_presence_of :title, :message => "Name der Mitarbeiterliste fehlt."
  validates_associated :employee_list_items
  
  after_update :save_employee_list_items
  
  # models/project.rb
  def employee_list_item_attributes=(employee_list_item_attributes)
    employee_list_item_attributes.each do |attributes|
      employee_list_items.build(attributes)
    end
  end
  
  def existing_employee_list_item_attributes=(employee_list_item_attributes)
    employee_list_items.reject(&:new_record?).each do |employee_list_item|
      attributes = employee_list_item_attributes[employee_list_item.id.to_s]
      if attributes
        employee_list_item.attributes = attributes
      else
        employee_list_items.delete(employee_list_item)
      end
    end
  end
  
  # call back function after updating
  def save_employee_list_items
    employee_list_items.each do |employee_list_item|
      employee_list_item.save(false) # don't validate
    end
  end
  
end
