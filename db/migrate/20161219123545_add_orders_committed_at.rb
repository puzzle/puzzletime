class AddOrdersCommittedAt < ActiveRecord::Migration[5.1]
  def change
    rename_column :orders, :completed_month_end_at, :completed_at
    add_column :orders, :committed_at, :date
  end
end
