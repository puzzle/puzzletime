class RemoveDefaultProjectId < ActiveRecord::Migration
  def up
    remove_column :employees, :default_project_id
  end
  
  def down
    add_column :employees, :default_project_id, :integer
  end
end
