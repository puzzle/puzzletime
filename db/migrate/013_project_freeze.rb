class ProjectFreeze < ActiveRecord::Migration
  def self.up
      add_column :projects, :freeze_until, :date
  end

  def self.down
      remove_column :projects, :freeze_until
  end
end
