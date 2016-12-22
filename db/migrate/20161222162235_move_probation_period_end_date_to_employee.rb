class MoveProbationPeriodEndDateToEmployee < ActiveRecord::Migration
  def change
    add_column :employees, :probation_period_end_date, :date

    Employment.where('probation_period_end_date IS NOT NULL').includes(:employee).find_each do |e|
      e.employee.update_column(:probation_period_end_date, e.probation_period_end_date)
    end

    remove_column :employments, :probation_period_end_date
  end
end
