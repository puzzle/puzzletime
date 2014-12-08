class AddCommentToContactEmployeeOrderRelations < ActiveRecord::Migration
  def change
    rename_table :contacts_orders, :order_contacts
    change_table :order_contacts do |t|
      t.column :comment, :string
    end

    rename_table :employees_orders, :order_team_members
    change_table :order_team_members do |t|
      t.column :comment, :string
    end
  end
end
