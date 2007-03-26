class Complete < ActiveRecord::Migration
  def self.up
    add_column :projectmemberships, :last_completed, :date
  end

  def self.down
    remove_column :projectmemberships, :last_completed
  end
end
