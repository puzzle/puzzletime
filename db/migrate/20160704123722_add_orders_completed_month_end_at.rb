class AddOrdersCompletedMonthEndAt < ActiveRecord::Migration[5.1]
  def change
    add_column :orders, :completed_month_end_at, :date
  end
end
