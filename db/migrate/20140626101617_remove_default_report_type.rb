class RemoveDefaultReportType < ActiveRecord::Migration
  def up
    remove_column :employees, :report_type
  end

  def down
    add_column :employees, :report_type, :string
  end

end
