class AddEmployeesCommittedWorktimesAt < ActiveRecord::Migration[5.1]
  def change
    add_column :employees, :committed_worktimes_at, :date
  end
end
