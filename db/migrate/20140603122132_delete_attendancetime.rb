class DeleteAttendancetime < ActiveRecord::Migration
  def change
    remove_column :employees, :default_attendance
    Worktime.delete_all("type = 'Attendancetime'")
  end
end
