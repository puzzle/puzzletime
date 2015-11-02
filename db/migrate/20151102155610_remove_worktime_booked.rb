class RemoveWorktimeBooked < ActiveRecord::Migration
  def up
    remove_column :worktimes, :booked
  end

  def down
    add_column :worktimes, :booked, :boolean, null: false, default: false
  end
end
