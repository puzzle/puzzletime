class RemoveDefaultReportType < ActiveRecord::Migration
  def up
    remove_column :employees, :report_type
  end

  def down
    add_column :employees, :report_type, :string
    execute('ALTER TABLE employees ADD CONSTRAINT chk_report_type CHECK (report_type IN(\'start_stop_day\' , \'absolute_day\' , \'week\' , \'month\' ))')
  end

end
