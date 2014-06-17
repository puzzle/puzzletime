class RemoveCompletion < ActiveRecord::Migration
  def up
    remove_column :projectmemberships, :last_completed
  end

  def down
    add_column :projectmemberships, :last_completed, :date
  end
end
