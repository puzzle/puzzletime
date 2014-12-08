class CreateWorkingConditions < ActiveRecord::Migration
  def change
    create_table :working_conditions do |t|
      t.date :valid_from
      t.decimal :vacation_days_per_year, precision: 5, scale: 2, null: false
      t.decimal :must_hours_per_day, precision: 4, scale: 2, null: false
    end

    WorkingCondition.create!(vacation_days_per_year: 25, must_hours_per_day: 8)
  end
end
