class BookAndOthers < ActiveRecord::Migration
  def self.up
    # booking worktimes
    add_column :worktimes, :booked, :boolean, :default => false
    
    # project specific settings
    add_column :projects, :billable, :boolean, :default => true
    add_column :projects, :report_type, :string, :default => 'month'
    add_column :projects, :description_required, :boolean, :default => false    
    execute('ALTER TABLE projects ADD CONSTRAINT chkname_report CHECK (report_type IN(\'start_stop_day\' , \'absolute_day\' , \'week\' , \'month\' ))')
    
    # set default values for projects
    Project.find(:all).each do |project|
      project.update_attributes(:billable => false, 
                                :report_type => 'month', 
                                :description_required => false)
    end
    
    # overtime as vacation
    create_table :overtime_vacations do |t|
      t.column :hours, :float, :null => false
      t.column :employee_id, :integer, :null => false
      t.column :transfer_date, :date, :null => false
    end
  end

  def self.down
    drop_table :overtime_vacations
  
    execute('ALTER TABLE projects DROP CONSTRAINT chkname_report')
    remove_column :projects, :description_required
    remove_column :projects, :report_type
    remove_column :projects, :billable        
    
    remove_column :worktimes, :booked    
  end
end
