# Creates the tables and relations between them for the project puzzletime
# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class AddTables < ActiveRecord::Migration
  
  def self.up                 
    
    #creates table employees
    create_table :employees do |t|                      
      t.column :firstname, :string, :null => false
      t.column :lastname, :string, :null => false
      t.column :shortname, :string, :limit => 3, :null => false
      t.column :passwd, :string, :null => false
      t.column :email, :string, :null => false
      t.column :phone, :string, :null => false
      t.column :managment, :boolean, :default => 'false'
    end
 
    #creates table clients
    create_table :clients do |t|                        
      t.column :name, :string, :null => false
      t.column :contact, :string, :null => false
    end
 
    #creates table absences
    create_table :absences do |t|
      t.column :name, :string, :null => false
      t.column :payed, :boolean, :default => 'false'
    end
    
    #creates table holidays
    create_table :holidays do |t|
      t.column :holiday_date, :date , :null => false
      t.column :musthours_day, :float, :null => false
    end
    
    #creates table masterdata
    create_table :masterdata do |t|
      t.column :musthours_day, :float, :null => false
      t.column :vacations_year, :integer, :null => false
    end
    
    #creates table employments
    create_table :employments do |t|
      t.column :employee_id, :integer
      t.column :percent, :integer, :null => false
      t.column :start_date, :date, :null => false
      t.column :end_date, :date, :null => false
    end
    
    #creates table projectmemberships
    create_table :projectmemberships do |t|
      t.column :project_id, :integer
      t.column :employee_id, :integer
      t.column :management, :boolean, :default => 'false'
    end
    
    #creates table projects
    create_table :projects do |t|
      t.column :client_id, :integer
      t.column :name, :string, :null => false
      t.column :description, :text
    end
    
    #creates table times
    create_table :times do |t|
      t.column :project_id, :integer
      t.column :absence_id, :integer
      t.column :employee_id, :integer
      t.column :report_type, :string, :null => false
      t.column :work_date, :date, :null => false
      t.column :hours, :time
      t.column :from_start_time, :time
      t.column :to_end_time, :time
      t.column :description, :text 
      t.column :billable, :boolean, :default => 'true'
      t.column :booked, :boolean, :default => 'false'
    end
    
    #executes some SQL-queries to get the relations of the tables onto the Postgresql-DB
    execute('ALTER TABLE employments ADD CONSTRAINT fk_employments_employees FOREIGN KEY ( employee_id ) REFERENCES employees( id ) ')
    execute('ALTER TABLE projectmemberships ADD CONSTRAINT fk_projectmemberships_employees FOREIGN KEY ( employee_id ) REFERENCES employees( id ) ')
    execute('ALTER TABLE projectmemberships ADD CONSTRAINT fk_projectmemberships_projects FOREIGN KEY ( project_id ) REFERENCES projects( id ) ')
    execute('ALTER TABLE projects ADD CONSTRAINT fk_projects_clients FOREIGN KEY ( client_id ) REFERENCES clients( id ) ')
    execute('ALTER TABLE times ADD CONSTRAINT fk_times_employees FOREIGN KEY ( employee_id ) REFERENCES employees( id ) ')  
    execute('ALTER TABLE times ADD CONSTRAINT fk_times_projects FOREIGN KEY ( project_id ) REFERENCES projects( id ) ')
    execute('ALTER TABLE times ADD CONSTRAINT fk_times_absences FOREIGN KEY ( absence_id ) REFERENCES absences( id ) ')
    execute('ALTER TABLE times ADD CONSTRAINT chkname CHECK (report_type IN(\'start_stop_day\' , \'absolute_day\' , \'week\' , \'month\' ))')
  end
   
    #removes the tables listed below in case of back-migration
  def self.down
   drop_table :times
   drop_table :masterdata
   drop_table :holidays
   drop_table :employments
   drop_table :projectmemberships
   drop_table :projects
   drop_table :clients
   drop_table :absences
   drop_table :employees
  end
end
