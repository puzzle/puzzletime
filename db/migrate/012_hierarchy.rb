class Hierarchy < ActiveRecord::Migration
  def self.up
    transaction do
      # departments table
      create_table :departments do |t|
        t.column :name, :string, :null => false
        t.column :shortname, :string, :limit => 3, :null => false
      end
      
      # hierarchy columns for projects
      add_column :projects, :parent_id, :integer
      add_column :projects, :department_id, :integer
      execute('ALTER TABLE projects ADD COLUMN path_ids INTEGER[]')
      change_column :projects, :shortname, :string, :limit => 3, :null => true
      
      Project.find(:all).each do |project|
        project.update_attributes :path_ids => [project.id]
      end
      
      execute('ALTER TABLE projects ADD CONSTRAINT fk_project_parent FOREIGN KEY ( parent_id ) REFERENCES projects ( id ) ON DELETE CASCADE')
      execute('ALTER TABLE projects ADD CONSTRAINT fk_project_department FOREIGN KEY ( department_id ) REFERENCES departments ( id ) ON DELETE SET NULL')
   
      # active flag for projectmemberships
      add_column :projectmemberships, :active, :boolean, :default => true
      Projectmembership.update_all( 'active = true' )
      Worktime.find(:all, :joins => 'LEFT OUTER JOIN projectmemberships p ON ' +
                                    'worktimes.project_id = p.project_id AND worktimes.employee_id = p.employee_id',
                          :conditions => ["p.id IS NULL AND worktimes.type = 'Projecttime'"]).each do |time|
        Projectmembership.create(:project_id => time.project_id, 
                                   :employee_id => time.employee_id,
                                   :active => false)      
      end
    end
  end

  def self.down
    transaction do
      Projectmembership.delete_all('active = false')
      execute('ALTER TABLE projects DROP CONSTRAINT fk_project_parent')
      execute('ALTER TABLE projects DROP CONSTRAINT fk_project_department')
      
      remove_column :projectmemberships, :active
      remove_column :projects, :path_ids
      remove_column :projects, :department_id
      remove_column :projects, :parent_id
      change_column :projects, :shortname, :string, :limit => 3, :null => false
      
      drop_table :departments
    end
  end
end
