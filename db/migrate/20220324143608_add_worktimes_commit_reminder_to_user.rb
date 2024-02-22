# frozen_string_literal: true

class AddWorktimesCommitReminderToUser < ActiveRecord::Migration[5.2]
  def change
    add_column :employees, :worktimes_commit_reminder, :boolean, default: true, null: false
  end
end
