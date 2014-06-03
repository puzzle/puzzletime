class DeleteAttendancetime < ActiveRecord::Migration
  def change
    Worktime.delete_all("type = 'Attendancetime'")
  end
end
