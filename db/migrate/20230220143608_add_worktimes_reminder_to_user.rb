class AddWorktimesReminderToUser < ActiveRecord::Migration[5.2]
  def change
    add_column :employees, :worktimes_reminder, :boolean, default: false, null: false
  end
end
