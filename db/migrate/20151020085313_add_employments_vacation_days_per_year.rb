class AddEmploymentsVacationDaysPerYear < ActiveRecord::Migration
  def change
    add_column :employments, :vacation_days_per_year, :decimal, precision: 5, scale: 2
  end
end
