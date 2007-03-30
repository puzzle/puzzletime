class Attendance < ActiveRecord::Migration
  def self.up
    add_column :worktimes, :type, :string
    
    # set types for worktimes
    execute("UPDATE worktimes SET type = 'Projecttime' WHERE project_id IS NOT NULL")
    execute("UPDATE worktimes SET type = 'Absencetime' WHERE absence_id IS NOT NULL")
    
    Projecttime.find(:all).each do |time|
      Attendancetime.create({:employee_id     => time.employee_id,
                             :report_type     => time.report_type,
                             :work_date       => time.work_date,
                             :hours           => time.hours,
                             :from_start_time => time.from_start_time,
                             :to_end_time     => time.to_end_time})      
    end
  end

  def self.down
    Attendancetime.delect_all
    remove_column :worktimes, :type    
  end
end
