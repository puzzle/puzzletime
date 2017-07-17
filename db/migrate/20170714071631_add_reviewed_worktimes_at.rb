class AddReviewedWorktimesAt < ActiveRecord::Migration[5.1]
  def change
    add_column :employees, :reviewed_worktimes_at, :date, { after: :committed_worktimes_at }
  end
end
