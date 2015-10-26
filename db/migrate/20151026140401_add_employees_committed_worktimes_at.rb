class AddEmployeesCommittedWorktimesAt < ActiveRecord::Migration
  def change
    add_column :employees, :committed_worktimes_at, :date
  end
end
