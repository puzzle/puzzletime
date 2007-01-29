class BookAndOthers < ActiveRecord::Migration
  def self.up
    add_column :worktimes, :booked, :boolean, :default => false
  end

  def self.down
    remove_column :worktimes, :booked
  end
end
