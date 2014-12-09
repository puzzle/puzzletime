class AddAllowLocalFlagToClients < ActiveRecord::Migration
  def change
    add_column :clients, :allow_local, :boolean, null: false, default: false
  end
end
