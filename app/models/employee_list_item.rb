class EmployeeListItem < ActiveRecord::Base
  
  belongs_to :employee_list
  has_many :employees
  
  validates_presence_of :employee_id
  
  # ignore duplicates: an employee can only be once on a certain list
  validates_uniqueness_of :employee_id, :scope => [:employee_list_id]
  
end
