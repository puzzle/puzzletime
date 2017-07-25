class AddOrderStatusDefault < ActiveRecord::Migration[5.1]
  def change
    add_column :order_statuses, :default, :boolean, { default: false, null: false }

    first_order_status = OrderStatus.list.first
    first_order_status.default = true
    first_order_status.save!
  end
end
