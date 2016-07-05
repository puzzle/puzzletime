class AddOrdersCompletedMonthEndAt < ActiveRecord::Migration
  def change
    add_column :orders, :completed_month_end_at, :date
  end
end
