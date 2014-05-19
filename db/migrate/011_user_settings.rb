class UserSettings < ActiveRecord::Migration
  def self.up
    add_column :employees, :report_type, :string
    add_column :employees, :default_attendance, :boolean, :default => false
    add_column :employees, :default_project_id, :integer
    execute('ALTER TABLE employees ADD COLUMN user_periods VARCHAR(3)[]')
    execute('ALTER TABLE employees ADD COLUMN eval_periods VARCHAR(3)[]')
    Employee.list.each do |e|
      e.update_attributes :user_periods => ['0d', '0w', '0m'],
                          :eval_periods => ['0w', '-1m', '0m', '0y', '0']
    end

    execute('ALTER TABLE employees ADD CONSTRAINT chk_report_type CHECK (report_type IN(\'start_stop_day\' , \'absolute_day\' , \'week\' , \'month\' ))')

    add_column :projects, :offered_hours, :float
  end

  def self.down
    remove_column :projects, :offered_hours
    remove_column :employees, :user_periods
    remove_column :employees, :default_project_id
    remove_column :employees, :default_attendance
    remove_column :employees, :report_type
  end
end
