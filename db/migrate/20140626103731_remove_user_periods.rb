class RemoveUserPeriods < ActiveRecord::Migration
  def up
    remove_column :employees, :user_periods
  end

  def down
    execute('ALTER TABLE employees ADD COLUMN user_periods VARCHAR(3)[]')
    Employee.update_all(:user_periods => ['0d', '0w', '0m'])
  end

end
