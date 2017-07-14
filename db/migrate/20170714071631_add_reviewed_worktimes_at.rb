class AddReviewedWorktimesAt < ActiveRecord::Migration
  def change
    add_column :employees, :reviewed_worktimes_at, :date, { after: :committed_worktimes_at }
  end
end
