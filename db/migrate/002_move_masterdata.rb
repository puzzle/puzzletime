class MoveMasterdata < ActiveRecord::Migration
  def self.up
    drop_table :masterdatas
    add_column :employees, :initial_vacation_days, :float, :default => 0
  end

  def self.down
    remove_column :employees, :initial_vacation_days
    # Creates table masterdata
    create_table :masterdatas do |t|
      t.column :musthours_day, :float, :null => false
      t.column :vacations_year, :integer, :null => false
    end
  end
end
