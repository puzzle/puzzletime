class Ticketing < ActiveRecord::Migration
  
  def self.up
      add_column :worktimes, :ticket, :string
      add_column :projects, :ticket_required, :boolean, :default => false
      execute "UPDATE projects SET ticket_required = false;"
  end

  def self.down
      remove_column :worktimes, :ticket
      remove_column :projects, :ticket_required
  end
  
end