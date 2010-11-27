class CreateEmployeeLists < ActiveRecord::Migration
  def self.up
    
    # employee lists
    create_table :employee_lists do |t|
      t.integer :employee_id, :null => false
      t.string :title, :null => false

      t.timestamps
    end
    
    # items contained in an employee list
    create_table :employee_list_items do |t|
      t.integer :employee_list_id, :null => false
      t.integer :employee_id, :null => false

      t.timestamps
    end
  end

  def self.down
    drop_table :employee_list_items
    drop_table :employee_lists
  end
end
