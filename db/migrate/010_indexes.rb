class Indexes < ActiveRecord::Migration
  def self.up
    execute "CREATE INDEX worktimes_projects ON worktimes (project_id, employee_id, work_date) WHERE type = 'Projecttime'"
    execute "CREATE INDEX worktimes_absences ON worktimes (absence_id, employee_id, work_date) WHERE type = 'Absencetime'"
    execute "CREATE INDEX worktimes_attendances ON worktimes (employee_id, work_date) WHERE type = 'Attendancetime'"
    execute "ANALYZE worktimes"
    
    add_index :projects, :client_id
    add_index :employments, :employee_id
    add_index :projectmemberships, :project_id
    add_index :projectmemberships, :employee_id

    execute "ANALYZE projects"
    execute "ANALYZE employments"
    execute "ANALYZE projectmemberships"
  end

  def self.down
    # run sql because rails flexes the given index name in remove_index
    execute "DROP INDEX worktimes_projects"
    execute "DROP INDEX worktimes_absences"
    execute "DROP INDEX worktimes_attendances"
    
    remove_index :projects, :client_id
    remove_index :employments, :employee_id
    remove_index :projectmemberships, :project_id
    remove_index :projectmemberships, :employee_id
  end
end
