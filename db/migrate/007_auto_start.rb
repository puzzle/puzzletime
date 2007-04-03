class AutoStart < ActiveRecord::Migration
  def self.up
     execute('ALTER TABLE worktimes DROP CONSTRAINT chkname') 
     execute('ALTER TABLE worktimes ADD CONSTRAINT chkname CHECK (report_type IN(\'start_stop_day\' , \'absolute_day\' , \'week\' , \'month\' , \'auto_start\' ))')
  end

  def self.down
    execute('ALTER TABLE worktimes DROP CONSTRAINT chkname') 
    execute('ALTER TABLE worktimes ADD CONSTRAINT chkname CHECK (report_type IN(\'start_stop_day\' , \'absolute_day\' , \'week\' , \'month\' ))')
  end
end
