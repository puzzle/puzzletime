class CreatePlannings < ActiveRecord::Migration
  def self.up
    create_table :plannings do |t|
      t.integer :employee_id, :null => false
      t.integer :project_id, :null => false
      t.integer :start_week, :null => false
      t.integer :end_week
      t.boolean :definitive, :null => false, :default => false
      t.text :description
      t.boolean :monday_am, :null => false, :default => false
      t.boolean :monday_pm, :null => false, :default => false
      t.boolean :tuesday_am, :null => false, :default => false
      t.boolean :tuesday_pm, :null => false, :default => false
      t.boolean :wednesday_am, :null => false, :default => false
      t.boolean :wednesday_pm, :null => false, :default => false
      t.boolean :thursday_am, :null => false, :default => false
      t.boolean :thursday_pm, :null => false, :default => false
      t.boolean :friday_am, :null => false, :default => false
      t.boolean :friday_pm, :null => false, :default => false
      
      t.timestamps
    end
  end

  def self.down
    drop_table :plannings
  end
end
