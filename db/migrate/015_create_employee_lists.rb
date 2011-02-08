class CreateEmployeeLists < ActiveRecord::Migration
  def self.up
    
    # employee lists
    create_table :employee_lists do |t|
      t.integer :employee_id, :null => false
      t.string :title, :null => false
      t.timestamps
    end
    
    # employee lists join table
    create_table :employee_lists_employees, :id => false, :force => true do |t|
      t.integer :employee_list_id
      t.integer :employee_id
      t.timestamps
    end
    
  end

  def self.down
    drop_table :employee_lists
    drop_table :employee_lists_employees
  end
end
