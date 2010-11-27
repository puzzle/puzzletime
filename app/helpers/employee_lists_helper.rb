module EmployeeListsHelper
  
  def fields_for_employee_list_item(employee_list_item, &block)
    prefix = employee_list_item.new_record? ? 'new' : 'existing'
    fields_for("employee_list[#{prefix}_employee_list_item_attributes][]", employee_list_item, &block)
  end
  
  def add_employee_list_item_link(name) 
    link_to_function name do |page| 
      page.insert_html :bottom, :employee_list_items, :partial => 'employee_list_item', :object => EmployeeListItem.new 
    end 
  end 

  
end
