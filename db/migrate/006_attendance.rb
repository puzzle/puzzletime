class Attendance < ActiveRecord::Migration
  def self.up
    add_column :worktimes, :type, :string
    
    # set types for worktimes
    execute("UPDATE worktimes SET type = 'Projecttime' WHERE project_id IS NOT NULL")
    execute("UPDATE worktimes SET type = 'Absencetime' WHERE absence_id IS NOT NULL")
  end

  def self.down
    remove_column :worktimes, :type
  end
end
