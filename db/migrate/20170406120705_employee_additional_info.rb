class EmployeeAdditionalInfo < ActiveRecord::Migration
  def change
    change_table :employees do |t|
      t.text :additional_information
    end

    add_index :employment_roles, :name, unique: true
    add_index :employment_role_levels, :name, unique: true
    add_index :employment_role_categories, :name, unique: true
  end
end
